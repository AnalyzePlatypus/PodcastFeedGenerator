# PodcastFeedGenerator

Easily generate industry-standard podcast RSS feeds.

```ruby
require "podcast_feed_generator"

json = JSON.parse(File.open("feed.json").read) # A JSON file containing all of your podcast's info

rss_feed = PodcastFeedGenerator::Generator.new.generate json
```

## Installation

```
$ gem install podcast_feed_generator
```

Or add this line to your application's Gemfile:

```ruby
gem 'podcast_feed_generator'
```

## Usage

`PodcastFeedGenerator` has exactly one public method: `generate`, which expects a Ruby hash with the following shape:

```javascript
{
  "podcast": {
    "title": "Podcast Title",
    "description": "Podcast Description",
    "link": "link/to/show",
    "author": "Podcast author",
    "ownerName": "Podcast owner",
    "ownerEmail": "podcast@email.io",
    "podcastArtworkUrl": "link/to/feedImage",
     "categories": [ // Add up to three of the official iTunes categories: https://castos.com/itunes-podcast-category-list/
      "Category 1",
      "Category 2",
      "Category 3"
    ],

    // Optional
    "lastBuildDate": "2019-06-23",           // Defaults to current date
    "generator": "PodcastFeedGenerator gem", // Defaults to "PodcastFeedGenerator"
    "subtitle": "Podcast subtitle",          // Defaults to value of `description`
    "summary": "Podcast summary",            // Defaults to value of `description`
    "explicit": "no",                        // Can be one of `yes` | `no` | `explicit`.  Defaults to "no"
    "language": "en-US",                     // Defaults to `en-US`
    "podcastType": "Episodic",               // `Episodic` or `Serial`. `Episodic` causes iTunes to list newest first; `Serial`, oldest first
    "copyright": "(c) Podcast Copyright Notice" // Empty by default
  },
  "episodes": [
    {
      "title": "Episode Title",
      "author": "Episode Author",
      "pubDate": "2019-05-01",
      "link": "link/to/episode", 
      "description": "Episode description",
      "mediaFileUrl": "https://my-site.io/podcast/1",
      "duration": "00:33:12",
      "mediaFileSizeBytes": "34540230",

      // Optional
      "creator": "Episode Creator",               // Defaults to the `author` field above
      "subtitle": "Episode subtitle",             // Defaults to the episode `description`
      "summary": "Episode summary",               // Defaults to the episode `description`
      "explicit": "no",                           // Can be one of `yes` | `no` | `explicit`.  Defaults to "no"
      "episodeArtUrl": "path/to/episodeImage",    // Defaults to the podcast artwork url
      "itunesTitle": "Episode iTunes title",      // Special title to show in iTunes. Defaults to episode `title`
      "episodeNumber": "42",                      // Automatically generated if not specified.
      "seasonNumber": "2",                        // Empty by default
      "episodeType": "Full",                      // `full` | `trailer` | `bonus`. Defaults to `Full`. See the documentation for <itunes:episodeType> on https://help.apple.com/itc/podcasts_connect/#/itcb54353390
      "mediaMimeType": "audio/mpeg",              // Any media mime type. Defaults to "audio/mpeg"
      "mediaIsDefault": "true",                   // Defaults to true
      "medium": "audio"                           // `audio` | `video`
      "htmlDescription": "<div></div>",           // Defaults to the episode `description`
      "guid": "my.site/episodes/hjhkhl7829hs986", // Defaults to a 32-bit random string
      "guidIsPermalink": "false",                 // `false` by default. Set to `true` if your `guid` is a permalink url
    }
  ]
}
```

## See Also

* [Apple Podcasts Feed Guidelines](https://help.apple.com/itc/podcasts_connect/#/itc2b3780e76)
* [Apple Podcasts RSS Explained](https://help.apple.com/itc/podcasts_connect/#/itcb54353390)
* [Apple Podcasts Categories](https://help.apple.com/itc/podcasts_connect/#/itc9267a2f12)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/podcast_feed_generator.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
