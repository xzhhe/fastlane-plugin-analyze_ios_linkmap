require 'fastlane/action'
require_relative '../helper/analyze_ios_linkmap_parser'

module Fastlane
  module Actions
    module ShatedValues
      ANALYZE_IOS_LINKMAP_SEARCH_SYMBOL     = :ANALYZE_IOS_LINKMAP_SEARCH_SYMBOL
      ANALYZE_IOS_LINKMAP_PARSED_HASH       = :ANALYZE_IOS_LINKMAP_PARSED_HASH
      ANALYZE_IOS_LINKMAP_PARSED_JSON       = :ANALYZE_IOS_LINKMAP_PARSED_JSON
      ANALYZE_IOS_LINKMAP_PARSED_MERGE_HASH = :ANALYZE_IOS_LINKMAP_PARSED_MERGE_HASH
      ANALYZE_IOS_LINKMAP_PARSED_MERGE_JSON = :ANALYZE_IOS_LINKMAP_PARSED_MERGE_JSON
    end

    class AnalyzeIosLinkmapAction < Action
      def self.run(params)
        file_path     = params[:file_path]
        search_symbol = params[:search_symbol]
        all_objects   = params[:all_objects]  || false
        all_symbols   = params[:all_symbols]  || false
        merge_by_pod  = params[:merge_by_pod] || false

        UI.important("❗️[analyze_ios_linkmap_action:run] file_path: #{file_path}")
        UI.important("❗️[analyze_ios_linkmap_action:run] search_symbol: #{search_symbol}")
        UI.important("❗️[analyze_ios_linkmap_action:run] all_objects: #{all_objects}")
        UI.important("❗️[analyze_ios_linkmap_action:run] all_symbols: #{all_symbols}")
        UI.important("❗️[analyze_ios_linkmap_action:run] merge_by_pod: #{merge_by_pod}")

        linkmap_parser = Fastlane::Helper::LinkMap::Parser.new(
          if search_symbol
            {
              file_path: file_path,
              all_objects: true,
              all_symbols: true
            }
          else
            {
              file_path: file_path,
              all_objects: all_objects,
              all_symbols: all_symbols
            }
          end
        )

        # parse Linkmap.txt
        Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_HASH] = linkmap_parser.generate_hash
        Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_JSON] = linkmap_parser.generate_json

        # merge Linkmap.txt parsed all symbols by library
        if merge_by_pod
          Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_MERGE_HASH] = linkmap_parser.generate_merge_by_pod_hash
          Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_MERGE_JSON] = linkmap_parser.generate_merge_by_pod_json
        end

        # if search a symbol from Linkmap.txt
        if search_symbol
          Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_SEARCH_SYMBOL] = []
          linkmap_parser.generate_hash[:librarys].each do |lib|
            lib[:object_files].each do |obj|
              obj[:symbols].each do |symol|
                next unless symol[:name].include?(search_symbol)

                Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_SEARCH_SYMBOL] << {
                  library: lib[:name],
                  object_file: obj[:file_name],
                  symbol: symol[:name]
                }
              end
            end
          end
        end
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :file_path,
            description: "/your/path/to/linkmap.txt",
            verify_block: ->(value) {
              UI.user_error("❌ file_path not pass") unless value
              UI.user_error!("❌ file_path #{value} not exist") unless File.exist?(value)
            }
          ),
          FastlaneCore::ConfigItem.new(
            key: :search_symbol,
            description: "search your give symbol in linkmap.txt from what library",
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :all_symbols,
            description: "print a object fille all symbols ???",
            optional: true,
            default_value: false,
            is_string: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :all_objects,
            description: "print a library all object files ???",
            optional: true,
            default_value: false,
            is_string: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :merge_by_pod,
            description: "merge linkmap parsed hash by pod name ???",
            optional: true,
            default_value: false,
            is_string: false
          )
        ]
      end

      def self.example_code
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.description
        "iOS parse linkmap.txt to ruby Hash or JSON"
      end

      def self.authors
        ["xiongzenghui"]
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
