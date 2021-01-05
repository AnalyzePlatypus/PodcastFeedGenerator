require "podcast_feed_generator/version"

require 'json'
require 'uri'
require 'time'
require 'nokogiri'

# Constants

DEFAULT_GENERATOR_STRING = "Ruby PodcastFeedGenerator (https://github.com/AnalyzePlatypus/PodcastFeedGenerator)"

# Warning Strings

NO_ARTWORK_WARNING = "❗️ Warning: No podcast artwork has been set. The iTunes podcast directory will not accept podcasts the lack channel art.\n"
NO_DURATION_WARNING = "❗️ Warning: Episode #%{episode_number}: '%{episode_title}' is missing a duration. Some podcast players may reject your feed.\n"
NO_CATEGORIES_WARNING = "❗️ Warning: Your feed has no categories defined.\nThe iTunes podcast directory requires 3 categories to be present in your feed.\n"
NO_MEDIA_URL_WARNING = "❗️ Warning: Episode #%{episode_number}: '%{episode_title}' has no audio url defined.\nGot: %{url}\nThe episode will be unplayable and some podcast players may reject your feed.\n"
INVALID_URL_WARNING = "❗️ Warning: url `mediaFileUrl` appears to be invalid: %{url}.\nFound in Episode #%{episode_number}: '%{episode_title}'\nThe episode will be unplayable and some podcast players may reject your feed.\n"
MISSING_FILE_SIZE_WARNING = "❗️ Warning: Episode #%{episode_number}: '%{episode_title}' is missing media file size (Got: %{fileSize}). (Missing key: `mediaFileSizeBytes`)\n. Some podcast players may reject your feed."
DUPLICATE_GUID_WARNING = "❗️ Warning: Multiple episodes are using the same GUID: `%{guid}`.\nGUIDS should be unique.\nSome podcast players may reject your feed."

# Helpers

def url_valid? url
  URI.parse(url).kind_of?(URI::HTTP)
end

def detect_duplicate_guids episodes  
  episode_guids = episodes.map{|e| e["guid"]}
  length_before_uniq = episode_guids.length
  length_after_uniq = episode_guids.uniq.length

  id = episode_guids.group_by{|e| e}.keep_if{|_, e| e.length > 1}

  if length_after_uniq < length_before_uniq
    STDERR.puts DUPLICATE_GUID_WARNING % {
      guid: id
    } 
  end
end

def verifyHasArtwork channel_details
  STDERR.puts NO_ARTWORK_WARNING if channel_details["podcastArtworkUrl"].nil? || channel_details["podcastArtworkUrl"].empty?
end

def verifyHasCategories channel_details
  if channel_details["categories"].nil? || channel_details["categories"].empty?
    STDERR.puts NO_CATEGORIES_WARNING    
  end
end

def verifyHasDuration episode
  if  episode["duration"].nil?
    STDERR.puts NO_DURATION_WARNING % {
      episode_number: episode["episodeNumber"],
      episode_title: episode["title"]
    } 
  end
end

def verifyMediaFileUrl episode
  if  episode["mediaFileUrl"].nil? || episode["mediaFileUrl"].empty?
    STDERR.puts NO_MEDIA_URL_WARNING % {
      url: episode["mediaFileUrl"],
      episode_number: episode["episodeNumber"],
      episode_title: episode["title"]
    } 
  else 
    unless url_valid? episode["mediaFileUrl"]
      STDERR.puts INVALID_URL_WARNING % {
        url: episode["mediaFileUrl"],
        episode_number: episode["episodeNumber"],
        episode_title: episode["title"]
      } 
    end
  end
end

def verifyMediaFileBytes episode
  if  episode["mediaFileSizeBytes"].nil? || episode["mediaFileSizeBytes"].empty?
    STDERR.puts MISSING_FILE_SIZE_WARNING % {
      fileSize: episode["mediaFileSizeBytes"],
      episode_number: episode["episodeNumber"] || feed_info["episodes"].length - index,
      episode_title: episode["title"]
    } 
  end
end

module PodcastFeedGenerator
 
  class Generator
    def generate feed_info
      builder = Nokogiri::XML::Builder.new do |xml|

        detect_duplicate_guids feed_info["episodes"]
        verifyHasArtwork    feed_info["podcast"]
        verifyHasCategories feed_info["podcast"]

        xml.rss('xmlns:content' => "http://purl.org/rss/1.0/modules/content/",  "xmlns:wfw" => "http://wellformedweb.org/CommentAPI/", "xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd", "xmlns:dc" => "http://purl.org/dc/elements/1.1/", "xmlns:media" => "http://search.yahoo.com/mrss/",  "version" => "2.0") {
          channel_details = feed_info["podcast"]
          xml.channel {
            
              xml.title         channel_details["title"]
              xml.description   channel_details["description"]
              xml.link          channel_details["link"]
              xml.lastBuildDate channel_details["lastBuildDate"] || Time.now.rfc2822
              xml.generator     channel_details["generator"]     || DEFAULT_GENERATOR_STRING
              xml.language      channel_details["language"]     || "en-US"
              xml.copyright     channel_details["copyright"]

              xml['itunes'].author   channel_details["author"]
              xml['itunes'].subtitle channel_details["subtitle"]    || channel_details["description"]
              xml['itunes'].summary  channel_details["summary"]     || channel_details["description"]
              xml['itunes'].explicit channel_details["explicit"]    || "no"
              xml['itunes'].type     channel_details["podcastType"] || "episodic"

              xml['itunes'].owner {
                xml['itunes'].name  channel_details["ownerName"]
                xml['itunes'].email channel_details["ownerEmail"]
              }
              
              xml['itunes'].image("href"    =>     channel_details["podcastArtworkUrl"] )
              
              unless channel_details["categories"].nil?
                channel_details["categories"].each do |category_name|
                  xml['itunes'].category("text" => category_name)
                end
              end 
              

              episodes = feed_info["episodes"].each_with_index do |episode, index|
                episode["episodeNumber"] = episode["episodeNumber"] || (feed_info["episodes"].length - index)
              end

              feed_info["episodes"].each_with_index do |episode, index|
                
                verifyHasDuration episode
                verifyMediaFileUrl episode
                verifyMediaFileBytes episode

                xml.item {
                  xml.title episode["title"]
                  xml['dc'].creator episode["creator"] || channel_details["author"]
                  xml.pubDate episode["pubDate"]
                  xml.link episode["link"]
                  xml.guid("isPermalink": episode["guidIsPermalink"]){
                    xml.text episode["guid"] || (0...32).map { (65 + rand(26)).chr }.join
                  } 

                  xml.description episode["description"]
                  xml["content"].encoded {
                    xml.text "<![CDATA[#{episode["htmlDescription"]}]]>"
                  }
                  xml['itunes'].author episode["author"]
                  xml['itunes'].subtitle episode["subtitle"] || episode["description"]
                  xml['itunes'].summary episode["summary"] || episode["description"]
                  

                  xml['itunes'].explicit episode["explicit"] || 'no'
                  xml['itunes'].duration episode["duration"]
                  xml['itunes'].image("href"=> episode["episodeArtUrl"] || channel_details["podcastArtworkUrl"])
    
                  
                  xml['itunes'].episode episode["episodeNumber"]
                  xml['itunes'].season episode["seasonNumber"]

                  xml['itunes'].title episode["itunesTitle"] || episode["title"]
                  xml['itunes'].episodeType episode["episodeType"] || "full"
      
                  xml.enclosure(
                    "url" => episode["mediaFileUrl"], 
                    "type" => episode["mediaMimeType"] || "audio/mpeg",
                    "length" => episode["mediaFileSizeBytes"] 
                  )
    
                  xml['media'].content(
                    "url"=> episode["mediaFileUrl"], 
                    "type" => episode["mediaMimeType"] || "audio/mpeg",
                    "length" => episode["mediaFileSizeBytes"],
                    "isDefault" => episode["mediaIsDefault"] || "true", 
                    "medium" => episode["medium"] || "audio"
                  ) {
                    xml['media'].title("type" => "plain") {
                      xml.text episode["title"]
                    }
                  }
                }
              end
            }
          }
      end
      
      builder.to_xml
    end
  end
end
