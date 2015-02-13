require 'sqlite3'
require 'active_record'
require 'protected_attributes'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'test.db'
)

ActiveRecord::Schema.define(:version => 1) do
  create_table "artists", :force => true do |t|
    t.string   "name"
    t.string   "website"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "albums", :force => true do |t|
    t.string   "title"
    t.integer  "year"
    t.integer  "artist_id"
    t.string "producer"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "album_reviews", :force => true do |t|
    t.string   "message"
    t.integer  "album_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "songs", :force => true do |t|
    t.string   "title"
    t.integer  "album_id"
    t.integer  "artist_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", :force => true do |t|
    t.integer "amount"
    t.integer  "artist_id"
    t.integer  "fan_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fans", :force => true do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stalkers", :force => true do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "artists_stalkers", force: true, id: false do |t|
    t.integer :artist_id
    t.integer :stalker_id
  end

  create_table "producers", force: true do |t|
    t.string :name
    t.string :album
  end

  create_table "generic_metadata", force: true do |t|
    t.integer :linked_id
    t.string :linked_type
    t.string :some_stuff_about_the_link
  end
end

module MyApp
  class Artist < ActiveRecord::Base
    attr_accessible :name, :website

    has_many :albums
    has_many :songs
    has_many :payments
    has_many :fans, :through => :payments
    has_many :generic_metadata, as: :linked
    has_many :data_items, class_name: "GenericMetadatum", as: :linked

    has_and_belongs_to_many :stalkers
  end

  class Album < ActiveRecord::Base
    attr_accessible :title, :year, :artist
    scope :classic, -> { where("year < 1950") }

    belongs_to :artist
    has_many :songs
    has_many :album_reviews
    has_many :producers, foreign_key: :album
    has_many :generic_metadata, as: :linked
  end

  class AlbumReview < ActiveRecord::Base
    attr_accessible :message
    belongs_to :album
  end

  class Song < ActiveRecord::Base
    default_scope -> { order(id: :asc) }

    attr_accessible :title, :artist, :album

    has_many :generic_metadata, as: :linked
    belongs_to :artist
    belongs_to :album
  end

  class Payment < ActiveRecord::Base
    attr_accessible :amount, :artist

    belongs_to :artist
    belongs_to :fan
  end

  class Fan < ActiveRecord::Base
    attr_accessible :name
    has_many :payments
    has_many :generic_metadata, as: :linked
    has_many :artists, :through => :albums
  end

  class Stalker < ActiveRecord::Base
    attr_accessible :name
    has_and_belongs_to_many :artists
  end

  class Producer < ActiveRecord::Base
    attr_accessible :name
    belongs_to :album, foreign_key: :album
  end

  class GenericMetadatum < ActiveRecord::Base
    attr_accessible :some_stuff_about_the_link
    belongs_to :linked, polymorphic: true
  end
end
