$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'coveralls'
Coveralls.wear!

require "podcast_feed_generator"
require "minitest/autorun"

