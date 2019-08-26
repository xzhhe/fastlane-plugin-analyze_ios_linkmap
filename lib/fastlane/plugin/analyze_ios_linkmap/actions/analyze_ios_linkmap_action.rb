require 'fastlane/action'
# require_relative '../helper/analyze_ios_linkmap_helper'

module Fastlane
  module Actions
    class AnalyzeIosLinkmapAction < Action
      def self.run(params)
        UI.message("The analyze_ios_linkmap plugin is working!")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :linkmap,
            description: "/your/path/to/linkmap.txt",
            verify_block: ->(value) { 
              UI.user_error("❌ filepath not pass") unless value
              UI.user_error!("❌ filepath #{value} not exist") unless File.exist?(value)
            }
          ),
          FastlaneCore::ConfigItem.new(
            key: :output,
            description: "write linkmap.txt parsed result Hash to /your/path/to/output.txt",
            verify_block: ->(value) { 
              UI.user_error("❌ filepath not pass") unless value
            },
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :symbol,
            description: "search your give symbol in linkmap.txt from what library",
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :show_details,
            description: "show all symbols details ?",
            is_string: false,
            optional: true,
            default_value: false
          )
        ]
      end

      def self.description
        "iOS parse linkmap.txt to ruby Hash"
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
