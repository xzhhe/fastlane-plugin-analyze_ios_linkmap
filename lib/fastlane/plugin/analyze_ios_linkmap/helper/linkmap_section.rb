module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    module LinkMap
      require_relative 'analyze_ios_file_helper'

      # Sections:
      # Address	    Size    	  Segment	  Section
      # 0x1000048A0	0x055656A8	__TEXT	  __text
      # 0x105569F48	0x000090E4	__TEXT	  __stubs
      # 0x10557302C	0x000079D4	__TEXT	  __stub_helper
      # 0x10557AA00	0x002D4E1A	__TEXT	  __cstring

      class Section
        attr_accessor(:name, :symbol_size, :residual_size, :start_addr, :end_addr, :segment)

        def to_hash
          {
            name: @name,
            symbol_size: @symbol_size,
            format_symbol_size: FileHelper.format_size(@symbol_size),
            residual_size: @residual_size,
            format_residual_size: FileHelper.format_size(@residual_size),
            start_addr: @start_addr,
            end_addr: @end_addr,
            segment: @segment
          }
        end

        def initialize(line)
          lines = line.split(' ').map(&:strip)

          address = lines[0]
          size    = lines[1]
          segment = lines[2]
          section = lines[3]
          # puts "address: #{address}"
          # puts "size: #{size}"
          # puts "segment: #{segment}"
          # puts "section: #{section}"

          start_addr    = address.to_i(16)
          residual_size = size.to_i(16)
          end_addr      = start_addr + residual_size
          # puts "start_addr: #{start_addr}"
          # puts "residual_size: #{residual_size}"
          # puts "end_addr: #{end_addr}"

          @name          = section
          @symbol_size   = 0
          @residual_size = residual_size
          @start_addr    = start_addr
          @end_addr      = end_addr
          @segment       = segment
        end

        # 【注意】
        # `section name` may be dulicate in different segment
        # 所以使用 <segment_name + section_name> 作为 map 的 key 存储
        # @section_map[section.key] = section
        def key
          "#{segment}:#{name}".to_sym
        end

        def to_segment
          key.to_s.split(':')[0].to_sym
        end
      end
    end
  end
end