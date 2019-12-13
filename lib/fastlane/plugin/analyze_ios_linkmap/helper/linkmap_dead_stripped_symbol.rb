module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    module LinkMap
      require_relative 'analyze_ios_file_helper'

      # Dead Stripped Symbols:
      #           Size    	  File  Name
      # <<dead>> 	0x00000030	[ 26] ___destroy_helper_block_e8_32s40s48s
      # <<dead>> 	0x00000008	[ 26] ___copy_helper_block_e8_32s
      # <<dead>> 	0x00000008	[ 26] ___destroy_helper_block_e8_32s

      class DeadStrippedSymbol
        attr_accessor(:size, :file, :name, :invalid) #=> file 并不是【文件名】, 而是【文件 id】

        def initialize(line)
          if line =~ %r(^<<dead>>\s+0x(.+?)\s+\[(.+?)\]\w*)
            @size    = $1.to_i(16)
            @file    = $2.to_i
            @invalid = false
          else
            @invalid = true
            # UI.error "#{line.inspect} can not match symbol regular"
          end
        end

        def to_hash
          {
            size: @size,
            format_size: FileHelper.format_size(@size),
            file: @file,
            name: @name
          }
        end
      end
    end
  end
end