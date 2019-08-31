require 'fastlane/action'
require_relative '../helper/analyze_ios_linkmap_helper'

module Fastlane
  module Actions
    module ShatedValues
      ANALYZE_IOS_LINKMAP_SEARCH_SYMBOL = :ANALYZE_IOS_LINKMAP_SEARCH_SYMBOL
      ANALYZE_IOS_LINKMAP_PARED_HASH    = :ANALYZE_IOS_LINKMAP_PARED_HASH
      ANALYZE_IOS_LINKMAP_PARED_JSON    = :ANALYZE_IOS_LINKMAP_PARED_JSON
    end

    class AnalyzeIosLinkmapAction < Action
      def self.run(params)
        filepath = params[:filepath]
        search_symbol = params[:search_symbol]

        parser = Fastlane::Helper::LinkMap::Parser.new(filepath)

        if search_symbol
          Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_SEARCH_SYMBOL] = []
          parser.pretty_hash[:librarys].each do |lib|
            lib[:objects].each do |obj|
              obj[:symbols].each do |symol|
                next unless symol[:name].include?(search_symbol)

                Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_SEARCH_SYMBOL] << {
                  library: lib[:library],
                  object_file: obj[:object],
                  symbol: symol[:name]
                }
              end
            end
          end
        end

        Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARED_HASH] = parser.pretty_hash
        Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARED_JSON] = parser.pretty_json
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :filepath,
            description: "/your/path/to/linkmap.txt",
            verify_block: ->(value) { 
              UI.user_error("❌ filepath not pass") unless value
              UI.user_error!("❌ filepath #{value} not exist") unless File.exist?(value)
            }
          ),
          FastlaneCore::ConfigItem.new(
            key: :search_symbol,
            description: "search your give symbol in linkmap.txt from what library",
            optional: true
          )
        ]
      end

      def self.description
        "iOS parse linkmap.txt to ruby Hash or JSON"
      end

      def self.authors
        ["xiongzenghui"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        "iOS parse linkmap.txt to ruby Hash"
      end

      def self.is_supported?(platform)
        :ios == platform
      end
    end
  end
end
