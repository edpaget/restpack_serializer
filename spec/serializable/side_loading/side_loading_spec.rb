require 'spec_helper'

describe RestPack::Serializer::SideLoading do
  context "invalid :include" do
    before(:each) do
      FactoryGirl.create(:song)
    end

    context "an include to an inexistent model" do
      it "raises an exception" do
        exception = RestPack::Serializer::InvalidInclude
        message = ":wrong is not a valid include for MyApp::Song"

        expect do
          MyApp::SongSerializer.side_loads([MyApp::Song.first], RestPack::Serializer::Options.new(MyApp::SongSerializer, { "include" => "wrong" }))
        end.to raise_error(exception, message)
      end
    end

    context "an include to a model which has not been whitelisted with 'can_include'" do
      it "raises an exception" do
        payment = FactoryGirl.create(:payment)
        exception = RestPack::Serializer::InvalidInclude
        message = ":payments is not a valid include for MyApp::Artist"

        expect do
          MyApp::ArtistSerializer.side_loads([payment.artist], RestPack::Serializer::Options.new(MyApp::ArtistSerializer, { "include" => "payments" }))
        end.to raise_error(exception, message)
      end
    end
  end

  describe "#can_include" do
    class CustomSerializer
      include RestPack::Serializer
      attributes :a, :b, :c
    end
    it "defaults to empty array" do
      CustomSerializer.can_includes.should == []
    end

    it "allows includes to be specified" do
      class CustomSerializer
        can_include :model1
        can_include :model2, :model3
      end

      CustomSerializer.can_includes.should == [:model1, :model2, :model3]
    end
  end

  describe "#links" do
    MyApp::AlbumSerializer.links.should == {
      "albums.artist" => {
        :href => "/artists/{albums.artist}",
        :type => :artists
      },
      "albums.songs" => {
        :href => "/songs?album_id={albums.id}",
        :type => :songs
      },
      "albums.producers" => {
        :href => "/producers?album={albums.title}",
        :type => :producers
      }
    }

    it "applies custom RestPack::Serializer.config.href_prefix" do
      original = RestPack::Serializer.config.href_prefix
      RestPack::Serializer.config.href_prefix = "/api/v1"
      MyApp::AlbumSerializer.links["albums.artist"][:href].should == "/api/v1/artists/{albums.artist}"
      RestPack::Serializer.config.href_prefix = original
    end

    it "applies custom serializer  href_prefix" do
      original = RestPack::Serializer.config.href_prefix
      MyApp::AlbumSerializer.href_prefix = '/api/v2'
      MyApp::AlbumSerializer.links["albums.artist"][:href].should == "/api/v2/artists/{albums.artist}"
      MyApp::AlbumSerializer.href_prefix = original
    end

    it "applies a custom url to links" do
      MyApp::ProducerSerializer.url("prods")
      MyApp::AlbumSerializer.links["albums.producers"][:href].should == "/prods?album={albums.title}"
      MyApp::ProducerSerializer.url("producers")
    end

    it "should not include polymorphic belongs to" do
      MyApp::GenericMetadatumSerializer.links.should == {}
    end
  end

  describe "#filterable_by" do
    context "a model with no :belongs_to relations" do
      it "is filterable by :id only" do
        MyApp::ArtistSerializer.filterable_by.should == [:id]
      end
    end
    context "a model with a single :belongs_to relations" do
      it "is filterable by primary key and foreign keys" do
        MyApp::AlbumSerializer.filterable_by.should =~ [:id, :artist_id, :year]
      end
    end
    context "a model with multiple :belongs_to relations" do
      it "is filterable by primary key and foreign keys" do
        MyApp::SongSerializer.filterable_by.should =~ [:id, :artist_id, :album_id, :title]
      end
    end
  end

  describe "sideloading the inverse polymorphic relation custom serialiser" do

    let(:artist) { FactoryGirl.create(:artist) }
    let(:datum) { FactoryGirl.create(:generic_metadatum, linked: artist) }
    let(:side_loads) do
      options = RestPack::Serializer::Options.new(MyApp::ArtistSerializer, { "include" => "data_items" })
      MyApp::ArtistSerializer.side_loads([artist], options)
    end

    context "when the specialised association serializer doesn't exist" do

      it "should use the class name serializer" do
        result = side_loads
        expect(result[:meta][:generic_metadata]).to_not be_nil
      end
    end

    context "when the association name serializer does exist" do
      let!(:serialiser) do
        class DataItemSerializer
          include RestPack::Serializer
          attributes :id, :some_stuff_about_the_link
          can_include :linked

          def self.key
            :data_items
          end

          def self.model_class
            MyApp::GenericMetadatum
          end
        end
      end

      it "should use the association name serializer" do
        result = side_loads
        expect(result[:meta][:data_items]).to_not be_nil
      end
    end
  end
end
