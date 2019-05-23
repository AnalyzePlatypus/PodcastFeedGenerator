require "test_helper"

#!/usr/bin/env ruby

require "minitest/autorun"
require 'minitest/reporters'
require "nokogiri"
require 'json'

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(:color => true)]

TEST_DATA_PATH = "./test/test_data.json"
MINIMAL_DATA_PATH = "./test/minimum.json"

# Helpers

def read_json_file filepath
  JSON.parse( File.open(filepath).read )
end


describe PodcastFeedGenerator::Generator do 

  before do
    @test_json = read_json_file TEST_DATA_PATH
    @generator = PodcastFeedGenerator::Generator.new
    raw_rss = @generator.generate @test_json
    @parsed_rss = Nokogiri::XML(raw_rss)
  end

  describe "channel details" do
    it "should add the title" do
      assert_equal @test_json["podcast"]["title"], @parsed_rss.css("rss>channel>title").text
    end

    it "should add the description" do
      assert_equal @test_json["podcast"]["description"], @parsed_rss.css("rss>channel>description").text
    end

    it "should add the channel link" do
      assert_equal @test_json["podcast"]["link"], @parsed_rss.css("rss>channel>link").text
    end

    it "should add the last build date" do
      assert_equal @test_json["podcast"]["lastBuildDate"], @parsed_rss.css("rss>channel>lastBuildDate").text
    end

    it "should add the generator" do
      assert_equal @test_json["podcast"]["generator"], @parsed_rss.css("rss>channel>generator").text
    end

    it "should add the author" do
      assert_equal @test_json["podcast"]["author"], @parsed_rss.css("rss>channel>itunes|author").text
    end

    it "should add the subtitle" do
      assert_equal @test_json["podcast"]["subtitle"], @parsed_rss.css("rss>channel>itunes|subtitle").text
    end

    it "should add the summary" do
      assert_equal @test_json["podcast"]["summary"], @parsed_rss.css("rss>channel>itunes|summary").text
    end

    it "should add the explicit status" do
      assert_equal @test_json["podcast"]["explicit"], @parsed_rss.css("rss>channel>itunes|explicit").text
    end

    it "should add the language" do
      assert_equal @test_json["podcast"]["language"], @parsed_rss.css("rss>channel>language").text
    end

    it "should add the owner name" do
      assert_equal @test_json["podcast"]["ownerName"], @parsed_rss.css("rss>channel>itunes|owner>itunes|name").text
    end

    it "should add the owner email" do
      assert_equal @test_json["podcast"]["ownerEmail"], @parsed_rss.css("rss>channel>itunes|owner>itunes|email").text
    end

    it "should add the copyright" do
      assert_equal @test_json["podcast"]["copyright"], @parsed_rss.css("rss>channel>copyright").text
    end

    it "should add the channel type" do
      assert_equal @test_json["podcast"]["podcastType"], @parsed_rss.css("rss>channel>itunes|type").text
    end

    it "should add the image" do
      assert_equal @test_json["podcast"]["podcastArtworkUrl"], @parsed_rss.css("rss>channel>itunes|image").attribute("href").value
    end

    it "should add the categories" do
      @test_json["podcast"]["categories"].each_with_index do |category_name, index|
        assert_equal category_name, @parsed_rss.css("rss>channel>itunes|category:nth-of-type(#{index + 1})").attribute("text").value
      end
    end


    describe "optional field default values" do
      before do 
        @mininum_json = read_json_file MINIMAL_DATA_PATH
        @generator = PodcastFeedGenerator::Generator.new
        raw_rss = @generator.generate @mininum_json
        @minimal_rss = Nokogiri::XML(raw_rss)
      end

      it "should generate a new build date if the source json doesn't have one" do
        #assert_equal @test_json["podcast"]["lastBuildDate"], @parsed_rss.css("rss>channel>lastBuildDate").text
      end

      it "should add a generator if the source json doesn't have one" do
        assert_equal "Ruby PodcastFeedGenerator (https://github.com/AnalyzePlatypus/PodcastFeedGenerator)", @minimal_rss.css("rss>channel>generator").text
      end

      it "should add a default explicit status of 'no' if the source json doesn't have one" do
        assert_equal "no", @minimal_rss.css("rss>channel>itunes|explicit").text
      end

      it "should add a default language status of 'en-US' if the source json doesn't have one" do
        assert_equal "en-US", @minimal_rss.css("rss>channel>language").text
      end

      it "should add a default podcast type status of 'Episodic' if the source json doesn't have one" do
        assert_equal "episodic", @minimal_rss.css("rss>channel>itunes|type").text
      end

      it "should set `subitle` to the `value` of `description` by default" do
        assert_equal @mininum_json["podcast"]["description"], @minimal_rss.css("rss>channel>itunes|subtitle").text
      end

      it "should set `summary` to the `value` of `description` by default" do
        assert_equal @mininum_json["podcast"]["description"], @minimal_rss.css("rss>channel>itunes|summary").text
      end

      it "should set `copyright` to an empty string by default" do
        assert_equal "", @minimal_rss.css("rss>channel>copyright").text
      end
    end
  end

  describe "episode details" do
    before do 
      @episode_json = @test_json["episodes"][0]
    end

    it "should set the episode title" do
      assert_equal @episode_json["title"], @parsed_rss.css("rss>channel>item:first-of-type>title").text
    end

    it "should set the episode guid" do
      assert_equal @episode_json["guid"], @parsed_rss.css("rss>channel>item:first-of-type>guid").text
    end

    it "should set the episode guid isPermalink" do
      assert_equal @episode_json["guidIsPermalink"], @parsed_rss.css("rss>channel>item:first-of-type>guid").attribute("isPermalink").value
    end

    it "should set the episode creator" do
      assert_equal @episode_json["creator"], @parsed_rss.css("rss>channel>item:first-of-type>dc|creator").text
    end

    it "should set the publication date" do
      assert_equal @episode_json["pubDate"], @parsed_rss.css("rss>channel>item:first-of-type>pubDate").text
    end

    it "should set the link" do
      assert_equal @episode_json["link"], @parsed_rss.css("rss>channel>item:first-of-type>link").text
    end

    it "should set the description" do
      assert_equal @episode_json["description"], @parsed_rss.css("rss>channel>item:first-of-type>description").text
    end

    it "should set the html description" do
      assert_match /#{@episode_json["htmlDescription"]}/, @parsed_rss.css("rss>channel>item:first-of-type>content|encoded").text
    end

    it "should add the author" do
      assert_equal @episode_json["author"], @parsed_rss.css("rss>channel>item:first-of-type>itunes|author").text
    end

    it "should add the subtitle" do
      assert_equal@episode_json["subtitle"], @parsed_rss.css("rss>channel>item:first-of-type>itunes|subtitle").text
    end

    it "should add the summary" do
      assert_equal @episode_json["summary"], @parsed_rss.css("rss>channel>item:first-of-type>itunes|summary").text
    end

    it "should add the explicit status" do
      assert_equal @episode_json["explicit"], @parsed_rss.css("rss>channel>item:first-of-type>itunes|explicit").text
    end

    it "should add the duration" do
      assert_equal @episode_json["duration"], @parsed_rss.css("rss>channel>item:first-of-type>itunes|duration").text
    end

    it "should add the episodeArtUrl" do
      assert_equal @episode_json["episodeArtUrl"], @parsed_rss.css("rss>channel>item:first-of-type>itunes|image").attribute('href').value
    end

    it "should add the episode iTunes title" do
      assert_equal @episode_json["itunesTitle"], @parsed_rss.css("rss>channel>item:first-of-type>itunes|title").text
    end

    it "should add the episode type" do
      assert_equal @episode_json["episodeType"], @parsed_rss.css("rss>channel>item:first-of-type>itunes|episodeType").text
    end

    it "should add the episode number" do
      assert_equal @episode_json["episodeNumber"], @parsed_rss.css("rss>channel>item:first-of-type>itunes|episode").text
    end

    it "should add the season number" do
      assert_equal @episode_json["seasonNumber"], @parsed_rss.css("rss>channel>item:first-of-type>itunes|season").text
    end

    describe "enclosure" do
      it "should add the enclosure media url" do
        assert_equal @episode_json["mediaFileUrl"], @parsed_rss.css("rss>channel>item:first-of-type>enclosure").attribute("url").value
      end

      it "should add the enclosure media mime type" do
        assert_equal @episode_json["mediaMimeType"], @parsed_rss.css("rss>channel>item:first-of-type>enclosure").attribute("type").value
      end

      it "should add the enclosure file size" do
        assert_equal @episode_json["mediaFileSizeBytes"], @parsed_rss.css("rss>channel>item:first-of-type>enclosure").attribute("length").value
      end
    end

    describe "media tag" do
      it "should add the media tag url" do
        assert_equal @episode_json["mediaFileUrl"], @parsed_rss.css("rss>channel>item:first-of-type>media|content").attribute("url").value
      end

      it "should add the media mime type" do
        assert_equal @episode_json["mediaMimeType"], @parsed_rss.css("rss>channel>item:first-of-type>media|content").attribute("type").value
      end

      it "should add the media isDefault key" do
        assert_equal @episode_json["mediaIsDefault"], @parsed_rss.css("rss>channel>item:first-of-type>media|content").attribute("isDefault").value
      end

      it "should add the media length" do
        assert_equal @episode_json["mediaFileSizeBytes"], @parsed_rss.css("rss>channel>item:first-of-type>media|content").attribute("length").value
      end

      it "should add the medium type" do
        assert_equal @episode_json["medium"], @parsed_rss.css("rss>channel>item:first-of-type>media|content").attribute("medium").value
      end

      it "should add the media title" do
        assert_equal @episode_json["title"], @parsed_rss.css("rss>channel>item:first-of-type>media|content>media|title").text
      end
    end



    describe "optional fields default values" do
      before do 
        @mininum_json = read_json_file MINIMAL_DATA_PATH
        @generator = PodcastFeedGenerator::Generator.new
        raw_rss = @generator.generate @mininum_json
        @minimal_rss = Nokogiri::XML(raw_rss)
      end

      it "should set `episode creator` to the feed author by default" do
        assert_equal @mininum_json["podcast"]["author"], @minimal_rss.css("rss>channel>item:first-of-type>dc|creator").text
      end

      it "should set the episode art to the feed art if none is supplied" do
        assert_equal @mininum_json["podcast"]["podcastArtworkUrl"], @minimal_rss.css("rss>channel>item:first-of-type>itunes|image").attribute('href').value
      end

      it "should set the episode guid to a large random number if none is supplied" do
        # assert_equal @mininum_json["podcast"]["podcastArtworkUrl"], @minimal_rss.css("rss>channel>item:first-of-type>itunes|image").attribute('href').value
      end

      it "should set `subtitle` to the value of `description` by default" do
        assert_equal @mininum_json["episodes"][0]["description"], @minimal_rss.css("rss>channel>item:first-of-type>itunes|subtitle").text
      end

      it "should set `summary` to the value of `description` by default" do
        assert_equal @mininum_json["episodes"][0]["description"], @minimal_rss.css("rss>channel>item:first-of-type>itunes|summary").text
      end

      it "should set `explicit` to the 'no' by default" do
        assert_equal "no", @minimal_rss.css("rss>channel>item:first-of-type>itunes|explicit").text
      end

      it "should set `itunesTitle` to the value of `title` by default" do
        assert_equal @mininum_json["episodes"][0]["title"], @minimal_rss.css("rss>channel>item:first-of-type>itunes|title").text
      end

      it "should set `episodeType` to `full` by default" do
        assert_equal "full", @minimal_rss.css("rss>channel>item:first-of-type>itunes|episodeType").text
      end

      it "should auto-generate episode numbers by default" do
        assert_equal "3", @minimal_rss.css("rss>channel>item:nth-of-type(1)>itunes|episode").text
        assert_equal "2", @minimal_rss.css("rss>channel>item:nth-of-type(2)>itunes|episode").text
        assert_equal "1", @minimal_rss.css("rss>channel>item:nth-of-type(3)>itunes|episode").text
      end

      it "should set the mime type to `audio/mpeg` by default" do
        assert_equal "audio/mpeg", @minimal_rss.css("rss>channel>item:first-of-type>enclosure").attribute("type").value
      end

      it "should set <media isDefault> to true by default" do
        assert_equal "true", @minimal_rss.css("rss>channel>item:first-of-type>media|content").attribute("isDefault").value
      end

      it "should set <media medium> to 'audio' by default" do
        assert_equal "audio", @minimal_rss.css("rss>channel>item:first-of-type>media|content").attribute("medium").value
      end
    end
  end

  describe "build warnings" do

    before do 
      @mininum_json = read_json_file MINIMAL_DATA_PATH
    end

    it "should warn when no podcastArtworkUrl is set" do
      @mininum_json["podcast"].delete "podcastArtworkUrl"
      out, err = capture_subprocess_io do
        @generator.generate @mininum_json
      end
      assert_match /No podcast artwork has been set/, err
    end

    it "should warn when the episode duration value is missing" do
      @mininum_json["episodes"][0].delete "duration"
      out, err = capture_subprocess_io do
        @generator.generate @mininum_json
      end
      assert_match /is missing a duration/, err
    end

    it "should warn when the episode duration value is invalid" do
      
    end

    it "should warn if no categories have been specified" do
      @mininum_json["podcast"].delete "categories"
      out, err = capture_subprocess_io do
        @generator.generate @mininum_json
      end
      assert_match %r%has no categories defined.%, err
    end

    it "should warn if the category is not on the official iTunes whitelist" do
      
    end

    it "should warn when an audioFileUrl is empty" do
      @mininum_json["episodes"][0].delete "mediaFileUrl"
      out, err = capture_subprocess_io do
        @generator.generate @mininum_json
      end
      assert_match %r%has no audio url defined%, err
    end

    it "should warn when an audioFileUrl is invalid" do
      @mininum_json["episodes"][0]["mediaFileUrl"] = "7891aghjkhv,..ahj19"
      out, err = capture_subprocess_io do
        @generator.generate @mininum_json
      end
      assert_match %r%appears to be invalid%, err
    end

    it "should warn when mediaFileSizeBytes is empty" do
      @mininum_json["episodes"][0].delete "mediaFileSizeBytes"
      out, err = capture_subprocess_io do
        @generator.generate @mininum_json
      end
      assert_match %r%is missing media file size%, err
    end

    it "should warn two guids are identical" do
      @mininum_json["episodes"][0]["guid"] = "1234"
      @mininum_json["episodes"][1]["guid"] = "1234"
      @mininum_json["episodes"][2]["guid"] = "1234"

      out, err = capture_subprocess_io do
        @generator.generate @mininum_json
      end
      assert_match %r%the same GUID%, err
    end
  end

  describe "url validation" do
    it "should  warn when the podcast image url is not available" do
      
    end

    it "should  warn when the episode image url is not available" do
      
    end

    it "should  warn when an audio file url is not available" do
      
    end
  end
end