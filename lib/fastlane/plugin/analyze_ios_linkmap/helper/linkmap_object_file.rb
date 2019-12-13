module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    module LinkMap
      require_relative 'analyze_ios_file_helper'

      # Object files:
      # ..........
      # [ 12] /Users/xiongzenghui/App/Pods/BangcleCryptoTool/BangcleCryptoTool/libs/libbangcle_crypto_tool.a(lsm4.o)
      # ..........
      # [ 25] /Users/xiongzenghui/App/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFHTTPSessionManager.o)
      # ------------------------------------------------------------------------------
      # @param  index : 25、26、...、31
      # @param  filename : AFHTTPSessionManager.o
      # @param  library : 所属 静态库 文件名
      # @param  framework : 如果 静态库 是 xx.framework 形态的, 则获取其 framework 名字
      # @param  symbols : 这个 AFHTTPSessionManager.o 包含的所有的 symbol 对象
      # @param  size : 所有符号的总大小
      # @param  dead_symbol_size: strip 掉的符号总大小
      #

      OBJECT_FILE_TYPE_USER_LIBRARY = 0
      OBJECT_FILE_TYPE_OTHERS       = 1
      OBJECT_FILE_TYPE_SYSTEM       = 2

      class ObjectFile
        attr_accessor(:index, :file_name, :library, :framework, :symbols, :size, :dead_symbol_size)
        alias framework? framework

        def initialize(line, &blk)
          if line =~ /\[(.*)\].*\/(.*)\((.*)\)/
            # [  5] /Users/xiongzenghui/App/Pods/BangcleCryptoTool/BangcleCryptoTool/libs/libbangcle_crypto_tool.a(aes.o)
            # [  6] /Users/xiongzenghui/App/Pods/BangcleCryptoTool/BangcleCryptoTool/libs/libbangcle_crypto_tool.a(crypto.o)
            # [  7] /Users/xiongzenghui/App/Pods/BangcleCryptoTool/BangcleCryptoTool/libs/libbangcle_crypto_tool.a(des.o)
            # ...............
            # [ 23] /Users/xiongzenghui/App/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFAutoPurgingImageCache.o)
            # [ 24] /Users/xiongzenghui/App/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFHTTPSessionManager.o)
            # [ 25] /Users/xiongzenghui/App/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFImageDownloader.o)

            index       = $1.to_i #=> 6 , 23
            library     = $2 #=> libbangcle_crypto_tool.a , AFNetworking
            file_name   = $3 #=> crypto.o , AFAutoPurgingImageCache.o
            # puts "index: #{index}"
            # puts "library: #{library}"
            # puts "file_name: #{file_name}"

            @index            = index
            @file_name        = file_name
            @library          = library
            @framework        = if line.include?('.framework')
                                  true
                                else
                                  false
                                end
            @symbols          = Array.new
            @size             = 0
            @dead_symbol_size = 0

            blk.call(self, OBJECT_FILE_TYPE_USER_LIBRARY)
          elsif line =~ /\[(.*)\].*\/(.*)/
            # [  3] /path/to/Release-iphoneos/App.build/Objects-normal/arm64/main.o
            # [100] /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.3.sdk/System/Library/Frameworks/UIKit.framework/UIKit.tbd
            # [9742] /path/to/Pods/du.framework/du
            # [8659] /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphoneos/libswiftDispatch.dylib

            index       = $1.to_i
            file_name   = $2
            # puts "index: #{index}"
            # puts "file_name: #{file_name}"

            @index            = index
            @file_name        = file_name
            @library          = if line.include?('.framework') && !file_name.include?('.') #=> /path/to/du.framework/du 【用户】动态库
                                  file_name
                                else
                                  if line.end_with?('.a') #=> \.a$ xcode 内置的 静态库
                                    file_name
                                  else
                                    if file_name.end_with?('.tbd') #=> \.tbd$ iOS 系统 动态库 软链接
                                      'tdb'
                                    elsif file_name.end_with?('.dylib') #=> \.dylib$ iOS 系统 动态库
                                      'dylib'
                                    elsif file_name.end_with?('.o') #=> \.o$ 用户 目标文件
                                      'main' #=> main.o、ZHUIAutoTest.o、swift.o ... 散落在 App 工程中的 xxx.o
                                    else
                                      'system'
                                    end
                                  end
                                end
            @framework        = if line.include?('.framework') && !file_name.include?('.')
                                  true
                                else
                                  false
                                end
            @symbols          = Array.new
            @size             = 0
            @dead_symbol_size = 0

            blk.call(self, OBJECT_FILE_TYPE_OTHERS)
          elsif line =~ /\[(.*)\]\s*([\w\s]+)/
            # [  0] linker synthesized
            # [  1] dtrace

            index       = $1.to_i
            file_name   = $2
            # puts "index: #{index}"
            # puts "file_name: #{file_name}"

            @index            = index
            @file_name        = file_name
            @library          = nil
            @framework        = false
            @symbols          = Array.new
            @size             = 0
            @dead_symbol_size = 0

            blk.call(self, OBJECT_FILE_TYPE_SYSTEM)
          end
        end

        def to_hash(all_symbols)
          h = {
            index: @index,
            file_name: @file_name,
            library: @library,
            size: @size,
            format_size: FileHelper.format_size(@size),
            dead_symbol_size: @dead_symbol_size,
            format_dead_symbol_size: FileHelper.format_size(@dead_symbol_size),
          }
          h[:symbols] = @symbols.map { |e| e.to_hash } if all_symbols
          h
        end

        # ObjectFile 追加 Symbol
        def add_symbol(symbol)
          @symbols.push(symbol)
          @size += symbol.size #=> 累加 ObjectFile 所有 Symbol 大小
        end
      end
    end
  end
end
