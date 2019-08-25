require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    module LinkMap
      # require 'pp'

      # Symbols:
      # Address	    Size    	  File    Name
      # 0x100001710	0x00000039	[  2]   -[ViewController viewDidLoad]
      Symbol = Struct.new(:address, :size, :object_file_id, :name)

      # Dead Stripped Symbols:
      #         	Size    	  File    Name
      # <<dead>> 	0x00000018	[  2]   CIE
      DeadStrippedSymbol = Struct.new(:size, :object_file_id, :name)

      # Sections:
      # Address	    Size    	  Segment	  Section
      # 0x100001710	0x00000333	__TEXT	  __text
      Section = Struct.new(:section, :segment, :start_addr, :end_addr, :symbol_size, :residual_size) do
        def key
          "#{segment}:#{section}".to_sym
        end

        def parse_segment
          key.to_s.split(':')[0].to_sym
        end
      end

      Segment = Struct.new(:name, :symbol_size, :residual_size)

      #<FastlaneCore::Helper::LinkMap::ObjectFile:0x007ff93ec4fc90
      # @file_id=39,
      # @framework=false,
      # @library="libbangcle_crypto_tool.a",
      # @symbols=[]
      # >
      ObjectFile = Struct.new(:file_id, :object, :library, :framework, :symbols, :size, :dead_symbol_size) 

      # {
      #   "AFNetworking"=>
      #     <struct FastlaneCore::Helper::LinkMap::Library
      #       name="AFNetworking",
      #       size=0,
      #       objects=[24],
      #       dead_symbol_size=0,
      #       pod_name="AFNetworking">
      # }
      Library = Struct.new(:name, :size, :objects, :dead_symbol_size, :pod_name)
      
      class Parser
        attr_accessor(:objects_map, :library_map, :section_map, :segment_map)

        def initialize(filepath)
          @filepath = filepath
          @objects_map = {}
          @library_map = {}
          @section_map = {}
          @segment_map = {} # 根据 @section_map 统计【所有的 section】得出
        end

        def pretty_json
          if @filepath.nil? && !File.exist?(@filepath)
            UI.user_error!("#{@filepath} not exist")
          end
          JSON.pretty_generate(pretty_hash)
        end

        def pretty_hash
          UI.user_error!("#{@filepath} not pass")  unless @filepath
          UI.user_error!("#{@filepath} not exist") unless File.exist?(@filepath)

          # 1.
          return @result if @result
          
          # 2.
          return parse
          
          # 3.
          # total_size = @library_map.values.map(&:size).inject(:+)
          
          # 4.
          # detail = @library_map.values.map do |lib|
          #   {
          #     library: lib.name,
          #     pod: lib.pod,
          #     size: lib.size,
          #     dead_symbol_size: lib.dead_symbol_size,
          #     objects: lib.objects.map do |obj|
          #       @objects_map[obj][:object]
          #     end
          #   }
          # end
          
        end

        def parse
          File.foreach(@filepath).with_index do |line, line_num|
            begin
              unless line.valid_encoding?
                line = line.encode("UTF-16", :invalid => :replace, :replace => "?").encode('UTF-8')
              end
  
              if line.start_with? "#"
                if line.start_with? "# Object files:"
                  @subparser = :parse_object_files
                elsif line.start_with? "# Sections:"
                  @subparser = :parse_sections
                elsif line.start_with? "# Symbols:"
                  @subparser = :parse_symbols
                elsif line.start_with? '# Dead Stripped Symbols:'
                  @subparser = :parse_dead
                end
              else
                send(@subparser, line) #=> self.func(line)
              end
            rescue => e
              UI.error "Exception on Link map file line #{line_num}"
              UI.message "Content is: "
              UI.message line
            end
          end
          # puts "There are #{@section_map.values.map{|value| value[:residual_size]}.inject(:+)} Byte in some section can not be analyze"
  
          # 对 objects_map 中的每一个 library/xx.o/symbols 进行排序
          @objects_map.each do |object_id, map|
            symbols = map[:symbols]
            next unless symbols
  
            symbols.sort! do |sym1, sym2|
              sym2[:size] <=> sym1[:size]
            end
          end
        end
  
        def parse_object_files(line)
          if line =~ %r(\[(.*)\].*\/(.*)\((.*)\))
            # Object files:
            # [  5] /Users/xiongzenghui/Desktop/launching_time/osee2unified/osee2unified/Pods/BangcleCryptoTool/BangcleCryptoTool/libs/libbangcle_crypto_tool.a(aes.o)
            # [  6] /Users/xiongzenghui/Desktop/launching_time/osee2unified/osee2unified/Pods/BangcleCryptoTool/BangcleCryptoTool/libs/libbangcle_crypto_tool.a(crypto.o)
            # [  7] /Users/xiongzenghui/Desktop/launching_time/osee2unified/osee2unified/Pods/BangcleCryptoTool/BangcleCryptoTool/libs/libbangcle_crypto_tool.a(des.o)
            # ...............
            # [ 23] /Users/zhihu/ci-jenkins/workspace/zhihu-iOS-module/VenomShellProject/osee2unified/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFAutoPurgingImageCache.o)
            # [ 24] /Users/zhihu/ci-jenkins/workspace/zhihu-iOS-module/VenomShellProject/osee2unified/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFHTTPSessionManager.o)
            # [ 25] /Users/zhihu/ci-jenkins/workspace/zhihu-iOS-module/VenomShellProject/osee2unified/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFImageDownloader.o)
            # ...........
  
            # 1.
            objc_file_id      = $1.to_i #=> 6、23
            library_name      = $2      #=> libbangcle_crypto_tool.a、AFNetworking
            object_file       = $3      #=> crypto.o、AFAutoPurgingImageCache.o

            # 2.
            of = ObjectFile.new(
              objc_file_id,
              object_file,
              library_name, 
              if line.include?('.framework')
                true
              else
                false
              end,
              Array.new,
              0,
              0
            )

            # 3.
            @objects_map[objc_file_id] = of
  
            # 4. 创建【静态库】对应的 map
            library = @library_map[library_name]
            library ||= Library.new(library_name, 0, [], 0, '')
  
            # 5. 【追加】 xx.o 文件位于 ``# Object Files`` 后面的 [ n] 标号
            library.objects << objc_file_id
  
            # 6. 确认 library 的 pod_name 名字
            if line.include?('/Pods/')
              # [ 23] /Users/zhihu/ci-jenkins/workspace/zhihu-iOS-module/VenomShellProject/osee2unified/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFAutoPurgingImageCache.o)
              divstr = line.split('/Pods/').last  #=> AFNetworking/AFNetworking.framework/AFNetworking(AFAutoPurgingImageCache.o
              pod_name = divstr.split('/').first  #=> AFNetworking
              library.pod_name = pod_name
            else
              library.pod_name = ''
            end
  
            # 7. 
            @library_map[library_name] = library
          elsif line =~ %r(\[(.*)\].*\/(.*))
            # [  3] /SomePath/Release-iphoneos/CrashDemo.build/Objects-normal/arm64/main.o
            # [100] /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.3.sdk/System/Library/Frameworks/UIKit.framework/UIKit.tbd
            # [9742] /SomePath/Pods/du.framework/du
            # [8659] /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphoneos/libswiftDispatch.dylib
  
            # 1.
            objc_file_id  = $1.to_i #=> 3
            object_file   = $2  #=> main.o
  
            # 2.
            library_name = ''
            if line.include?('.framework') && !object_file.include?('.') #=> /path/to/du.framework/du 【用户】动态库
              library_name = object_file
            else
              if line.end_with?('.a')
                library_name = object_file
              else
                library_name = if object_file.end_with?('.tbd')
                  'tdb'
                elsif object_file.end_with?('.dylib')
                  'dylib'
                elsif object_file.end_with?('.o')
                  'main'
                else
                  'system'
                end
              end
            end

            # 3.
            of = ObjectFile.new(
              objc_file_id,
              object_file,
              library_name, 
              if line.include?('.framework') && !object_file.include?('.')
                true
              else
                false
              end,
              Array.new,
              0,
              0
            )
  
            # 4.
            @objects_map[objc_file_id] = of
            # puts "#{objc_file_id} -- #{library_name}"

            # 5. 
            library = @library_map[library_name]
            library ||= Library.new(library_name, 0, [], 0, '')

            # 6.
            library.objects << objc_file_id
  
            # 7.
            @library_map[library_name] = library
          elsif line =~ /\[(.*)\]\s*([\w\s]+)/
            # Sample:
            # [  0] linker synthesized
            # [  1] dtrace

            # 1.
            objc_file_id = $1.to_i

            # 2.
            of = ObjectFile.new(
              objc_file_id,
              $2,
              '', 
              false,
              Array.new,
              0,
              0
            )

            # 3.
            @objects_map[objc_file_id] = of
          end
        end

        def parse_sections(line)
          # Sections:
          # Address	    Size    	  Segment	  Section
          # 0x1000048A0	0x055656A8	__TEXT	  __text
          # 0x105569F48	0x000090E4	__TEXT	  __stubs
          # 0x10557302C	0x000079D4	__TEXT	  __stub_helper
          # 0x10557AA00	0x002D4E1A	__TEXT	  __cstring
          #
  
          lines = line.split(' ').each(&:strip)
          section_name = lines[3]
          segment_name = lines[2]
          start_addr = lines.first.to_i(16)
          end_addr = start_addr + lines[1].to_i(16)
          residual_size = lines[1].to_i(16)
  
          section = Section.new(
            section_name, 
            segment_name,
            start_addr,
            end_addr,
            0,
            residual_size
          )

          # 【section name】may be dulicate in different segment
          # 所以使用 segment_name + section_name 作为 map 的 key 存储
          @section_map[section.key] = section
        end

        def parse_symbols(line)
          # Symbols:
          # Address	    Size    	  File    Name
          # 0x1000048A0	0x000000A4	[  2]   _main
          # 0x100004944	0x00000028	[  5]   _Bangcle_WB_AES_encrypt
  
          if line =~ %r(^0x(.+?)\s+0x(.+?)\s+\[(.+?)\]\s(.*))
            # 1.
            symbol_address = $1.to_i(16)  #=> Address
            symbol_size = $2.to_i(16)     #=> Size
            object_file_id = $3.to_i      #=> File
            symbol_name = $4              #=> Name
  
            # 2.
            object_file = @objects_map[object_file_id]
            
            # 3.
            unless object_file
              UI.error "#{line.inspect} can not found object file"
              return
            end

            # 4.
            symbol = Symbol.new(
              symbol_address,
              symbol_size,
              object_file_id,
              symbol_name
            )

            # 5. 追加【symbol】符号
            object_file.symbols.push(symbol)

            # 6. 【Object File】累加总大小
            object_file.size += symbol_size

            # 7. 【library/framework】累加总大小
            library = @library_map[object_file.library]
            library.size += symbol_size if library

            # 8. 【segment】累加总大小
            sections = @section_map.detect do |seg_sec_name, sec|
              if sec
                (sec.start_addr...sec.end_addr).include?(symbol_address)
              else
                false
              end
            end
            # pp "⚠️ seg_sec_names=#{seg_sec_names}"

            if sections
              section = sections[1]
              segment_name = section.parse_segment
              segment = @segment_map[segment_name]
              # pp "⚠️ segment_name=#{segment_name}"

              unless segment
                segment = Segment.new(segment_name, symbol_size, symbol_size)
              else
                segment.symbol_size += symbol_size
                segment.residual_size += symbol_size
              end
              # pp "⚠️ #{segment.name} #{segment.symbol_size} - #{segment.residual_size}"
              @segment_map[segment_name] = segment
            end
          else
            UI.error "#{line.inspect} can not match symbol regular"
          end
        end

        def parse_dead(line)
          # Dead Stripped Symbols:
          #           Size    	  File  Name
          # <<dead>> 	0x00000028	[  2] literal string: com.zhihu.audioBook.notifications.start
          # <<dead>> 	0x00000029	[  2] literal string: com.zhihu.audioBook.notifications.stoped
          # <<dead>> 	0x0000002A	[  2] literal string: com.zhihu.audioBook.notificaitons.loading
          # <<dead>> 	0x0000002A	[  2] literal string: com.zhihu.audioBook.notificaitons.palying
          # <<dead>> 	0x0000002D	[  2] literal string: com.zhihu.audioBook.notificaitons.paySuccess
          # <<dead>> 	0x00000006	[  2] literal string: appId
          # <<dead>> 	0x00000008	[  2] literal string: fakeURL
          # <<dead>> 	0x00000007	[  2] literal string: 300300
  
          if line =~ %r(^<<dead>>\s+0x(.+?)\s+\[(.+?)\]\w*)
            size = $1.to_i(16)
            file = $2.to_i

            object_file = @objects_map[file]
            return unless object_file
            
            # 累加 xx.o 的 dead symbol size
            object_file.dead_symbol_size += size

            # 累加 library(xx.o) 的 dead symbol size
            @library_map[object_file.library].dead_symbol_size += size
          end
        end
      end
    end
  end
end
