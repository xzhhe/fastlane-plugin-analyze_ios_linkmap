module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    module LinkMap
      require_relative 'analyze_ios_file_helper'

      # Symbols:
      # Address	    Size    	  File    Name
      # 0x1000048A0	0x000000A4	[  2]   _main
      # 0x100004944	0x00000028	[  5]   _Bangcle_WB_AES_encrypt
      #

      class Symbol
        attr_accessor(:address, :size, :file, :name, :invalid) #=> file 并不是【文件名】, 而是【文件 id】

        def initialize(line, &blk)
          if line =~ %r(^0x(.+?)\s+0x(.+?)\s+\[(.+?)\]\s(.*))
            @address     = $1.to_i(16) #=> Address
            @size        = $2.to_i(16) #=> Size
            @file        = $3.to_i     #=> File
            @name        = $4          #=> Name
            @invalid     = false
          else
            @invalid     = true
            # UI.error "#{line.inspect} can not match symbol regular"
          end
        end

        def to_hash
          {
            address: @address,
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