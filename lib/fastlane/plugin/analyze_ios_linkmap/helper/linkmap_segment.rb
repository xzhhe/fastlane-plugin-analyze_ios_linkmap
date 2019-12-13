module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    module LinkMap
      require_relative 'analyze_ios_file_helper'

      #
      # Linkmap.txt 结构中, 没有直接给出, 只能由【所有的 Section】累加计算得到
      #
      class Segment
        attr_accessor(:name, :size, :residual_size)
        
        def initialize(options = {})
          @name          = options[:name]
          @size          = options[:size]
          @residual_size = options[:residual_size]
        end

        def to_hash
          {
            name: @name,
            size: @size,
            format_size: FileHelper.format_size(@size),
            residual_size: @residual_size,
            format_residual_size: FileHelper.format_size(@residual_size)
          }
        end
      end
    end
  end
end
