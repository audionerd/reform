require "test_helper"

class PopulatorTest < MiniTest::Spec
  Album = Struct.new(:songs)
  Song  = Struct.new(:title)

  class Skip;end
  class AlbumForm < Reform::Form

    collection :songs, deserializer: {
          instance: ->(fragment, *options) {
            if fragment[:title] == "Good"
              Skip
            else
              songs << Song.new; songs.last
            end
             },
          # deserialize: ->(object, fragment, options) { puts "@@@@@ #{object.inspect}" },
          setter: nil
        } do
      property :title
    end
  end

  Deserializer = Disposable::Twin::Schema.from(AlbumForm,
      include:          [Representable::Hash::AllowSymbols, Representable::Hash],
      superclass:       Representable::Decorator,
      representer_from: lambda { |inline| inline.representer_class },
      options_from:     :deserializer,
      exclude_options:  [:default], # Reform must not copy Disposable/Reform-only options that might confuse representable.
    ) do |dfn|
      # next unless dfn[:twin]
      dfn.merge!(
        deserialize: lambda { |decorator, params, options|
          next if decorator.represented == Skip

          params = decorator.represented.deserialize!(params) # let them set up params. # FIXME: we could also get a new deserializer here.

          # DISCUSS: shouldn't we simply call represented.deserialize() here?
          decorator.from_hash(params) # options.binding.deserialize_method.inspect
        }
      ) if dfn[:twin]
    end

  it do
    form = AlbumForm.new(Album.new([]))
    hash = {songs: [{title: "Good"}, {title: "Bad"}]}

    Deserializer.new(form).from_hash hash

    puts form.inspect

    form.songs.size.must_equal 1
    form.songs[0].title.must_equal "Bad"
  end
end