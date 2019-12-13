module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    module LinkMap
      require_relative 'analyze_ios_file_helper'

      #
      # Linkmap.txt 结构中, 并没有这种结构, 自己抽象出的
      #

      class Library
        attr_accessor(:name, :size, :object_files, :dead_symbol_size, :podspec_name)

        def initialize(options = {})
          @name             = options[:name]
          @size             = options[:size]
          @object_files     = options[:object_files]
          @dead_symbol_size = options[:dead_symbol_size]
          @podspec_name     = options[:podspec_name]
        end

        def to_hash(all_objects)
          #
          # ─── FIX pod spec name ───────────────────────────────────────────────────────────
          #
          # <podspec name> ==> <library name>
          #
          # "AsyncSwift": "Async",
          # "Light-Untar": "Light_Untar",
          # "UIAlertView-Blocks": "UIAlertView_Blocks",
          # "UIDevice-Hardware": "UIDevice_Hardware",
          # "Yoga": "yoga",
          # "lottie-ios": "Lottie"
          #
          podspec_name = if @podspec_name
            @podspec_name                         # => 优先使用 podspec_name
          else
            @name                                 # => 如果【没有】podspec_name, 就使用 library_name 作为 podspec_name
          end

          h = {
            name: @name,
            size: @size,
            format_size: FileHelper.format_size(@size),
            dead_symbol_size: @dead_symbol_size,
            format_dead_symbol_size: FileHelper.format_size(@dead_symbol_size),
            podspec_name: podspec_name
          }
          h[:object_files] = @object_files if all_objects
          h
        end
      end
    end
  end
end
