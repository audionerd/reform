require "test_helper"

class PopulatorTest < MiniTest::Spec
  Album = Struct.new(:songs)
  Song  = Struct.new(:title)

  class AlbumForm < Reform::Form
    collection :songs, deserializer: {
          instance: ->(fragment, *options) { songs << Song.new; songs.last },
          # deserialize: ->(object, fragment, options) { puts "@@@@@ #{object.inspect}" }
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
          puts decorator.represented

          params = decorator.represented.deserialize!(params) # let them set up params. # FIXME: we could also get a new deserializer here.

          decorator.from_hash(params) # options.binding.deserialize_method.inspect
        }
      ) if dfn[:twin]
    end

  it do
    form = AlbumForm.new(Album.new([]))
    hash = {songs: [{title: "Good"}, {title: "Bad"}]}

    Deserializer.new(form).from_hash hash

    puts form.inspect
  end
end