require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    module LinkMap
      require 'pp'

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

      # Linkmap.txt 中, 没有直接给出, 只能由【所有的 Section】统计得出
      Segment = Struct.new(:name, :symbol_size, :residual_size)

      # 
      #<FastlaneCore::Helper::LinkMap::ObjectFile:0x007ff93ec4fc90
      #   @file_id=39,
      #   object="ViewController.o",
      #   @framework=false,
      #   @library="libbangcle_crypto_tool.a",
      #   @symbols=[
      #     <struct FastlaneCore::Helper::LinkMap::Symbol
      #       address=4294976749,
      #       size=15,
      #       object_file_id=2,
      #       name="literal string: ViewController"
      #     >,
      #     <struct FastlaneCore::Helper::LinkMap::Symbol
      #       address=4294974150,
      #       size=12,
      #       object_file_id=2,
      #       name="literal string: viewDidLoad"
      #     >
      #   ]
      # >
      ObjectFile = Struct.new(:file_id, :object, :library, :framework, :symbols, :size, :dead_symbol_size) 

      # 
      # "AFNetworking"=>
      #   <struct FastlaneCore::Helper::LinkMap::Library
      #     name="AFNetworking",
      #     size=0,
      #     object_file_ids=[23,24,25,26,27,28,29,30],
      #     dead_symbol_size=0,
      #     pod_name="AFNetworking"
      # >
      # 
      Library = Struct.new(:name, :size, :object_file_ids, :dead_symbol_size, :pod_name)
      
      class Parser
        attr_accessor(:object_map, :library_map, :section_map, :segment_map)

        def initialize(options)
          @filepath = options[:filepath]
          @all_symbols = options[:all_symbols]

          UI.user_error!("❌ #{@filepath} not pass")  unless @filepath
          UI.user_error!("❌ #{@filepath} not exist") unless File.exist?(@filepath)

          @object_map = {}
          @library_map = {}
          @section_map = {}
          @segment_map = {} # 根据 @section_map 统计【所有的 section】得出

          parse
        end

        def pretty_json
          JSON.pretty_generate(pretty_hash)
        end

        def pretty_hash
          return @result if @result

          # sort object_map[i].ObjectFile.symbols
          @object_map.each do |ofid, object|
            next unless object.symbols
  
            object.symbols.sort! do |sym1, sym2|
              sym2[:size] <=> sym1[:size]
            end
          end

          # 计算 linkmap.txt 所有的 symbol 总大小
          total_size = @library_map.values.map(&:size).inject(:+)
          total_dead_size = @library_map.values.map(&:dead_symbol_size).inject(:+)

          # sort object_map[i]
          library_map_values = @library_map.values.sort do |a, b|
            b.size <=> a.size
          end
          library_map_values.compact!

          library_maps = library_map_values.map do |lib|
            pod_name = lib.name
            unless lib.pod_name.empty?
              pod_name = lib.pod_name
            end

            if @all_symbols
              {
                library: lib.name,
                pod: pod_name,
                total: lib.size,
                format_total: Fastlane::Helper::LinkMap::FileHelper.format_size(lib.size),
                total_dead: lib.dead_symbol_size,
                format_total_dead: Fastlane::Helper::LinkMap::FileHelper.format_size(lib.dead_symbol_size),
                objects: lib.object_file_ids.map do |object_file_id|
                  # Struct.new(:file_id, :object, :library, :framework, :symbols, :size, :dead_symbol_size) 
                  object_file = @object_map[object_file_id]
                  if object_file
                    {
                      object: object_file.object,
                      symbols: object_file.symbols.map do |symb|
                        {
                          name: symb.name,
                          total: symb.size,
                          format_total: Fastlane::Helper::LinkMap::FileHelper.format_size(symb.size),
                        }
                      end
                    }
                  else
                    nil
                  end
                end
              }
            else
              {
                library: lib.name,
                pod: pod_name,
                total: lib.size,
                format_total: Fastlane::Helper::LinkMap::FileHelper.format_size(lib.size),
                total_dead: lib.dead_symbol_size,
                format_total_dead: Fastlane::Helper::LinkMap::FileHelper.format_size(lib.dead_symbol_size)
              }
            end
          end
          
          @result = {
            total_count: library_maps.count,
            total_size: total_size,
            format_total_size: Fastlane::Helper::LinkMap::FileHelper.format_size(total_size),
            total_dead_size: total_dead_size,
            format_total_dead_size: Fastlane::Helper::LinkMap::FileHelper.format_size(total_dead_size),
            librarys: library_maps
          }

          @result
        end

        def pretty_merge_by_pod_hash
          return @merge_by_pod_result if @merge_by_pod_result

          @merge_by_pod_result = {
            total_count: pretty_hash[:total_count],
            total_size: pretty_hash[:total_size],
            format_total_size: pretty_hash[:format_total_size],
            total_dead_size: pretty_hash[:total_dead_size],
            format_total_dead_size: pretty_hash[:format_total_dead_size]
          }

          pods = Hash.new
          pretty_hash[:librarys].each do |lib|
            apod_librarys = pods[lib[:pod]]
            apod_librarys ||= Array.new
            apod_librarys << lib
            pods[lib[:pod]] = apod_librarys
          end
          @merge_by_pod_result[:pods] = pods

          @merge_by_pod_result
        end

        def pretty_merge_by_pod_json
          JSON.pretty_generate(pretty_merge_by_pod_hash)
        end

        def parse
          # 读取 Linkmap.txt 【每一行】进行解析
          File.foreach(@filepath).with_index do |line, line_num|
            begin
              unless line.valid_encoding?
                line = line.encode("UTF-16", :invalid => :replace, :replace => "?").encode('UTF-8')
              end
  
              if line.start_with? "#"
                if line.start_with? "# Object files:" #=> 初始化 @object_map
                  @subparser = :parse_object_files
                elsif line.start_with? "# Sections:"  #=> 初始化 @section_map
                  @subparser = :parse_sections
                elsif line.start_with? "# Symbols:"   #=> 解析得到每一个 symbol 【占用】大小
                  @subparser = :parse_symbols
                elsif line.start_with? '# Dead Stripped Symbols:' #=> 解析得到 dead strpped 【废弃】大小
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
        end
  
        def parse_object_files(line)
          if line =~ %r(\[(.*)\].*\/(.*)\((.*)\))
            # Object files:
            # [  5] /Users/xiongzenghui/Desktop/launching_time/osee2unified/osee2unified/Pods/BangcleCryptoTool/BangcleCryptoTool/libs/libbangcle_crypto_tool.a(aes.o)
            # [  6] /Users/xiongzenghui/Desktop/launching_time/osee2unified/osee2unified/Pods/BangcleCryptoTool/BangcleCryptoTool/libs/libbangcle_crypto_tool.a(crypto.o)
            # [  7] /Users/xiongzenghui/Desktop/launching_time/osee2unified/osee2unified/Pods/BangcleCryptoTool/BangcleCryptoTool/libs/libbangcle_crypto_tool.a(des.o)
            # ...............
            # [ 23] /Users/xxx/ci-jenkins/workspace/xxx-iOS-module/VenomShellProject/osee2unified/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFAutoPurgingImageCache.o)
            # [ 24] /Users/xxx/ci-jenkins/workspace/xxx-iOS-module/VenomShellProject/osee2unified/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFHTTPSessionManager.o)
            # [ 25] /Users/xxx/ci-jenkins/workspace/xxx-iOS-module/VenomShellProject/osee2unified/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFImageDownloader.o)
            # ...........
  
            # 1.
            objc_file_id      = $1.to_i #=> 6 , 23
            library_name      = $2      #=> libbangcle_crypto_tool.a , AFNetworking
            object_file       = $3      #=> crypto.o , AFAutoPurgingImageCache.o

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

            # 3. 保存解析 xx.o (object file) 的数据
            @object_map[objc_file_id] = of
  
            # 4. 创建【静态库 library】对应的实体对象
            library = @library_map[library_name]
            library ||= Library.new(library_name, 0, [], 0, '')
  
            # 5. 【追加】 xx.o 文件位于 ``# Object Files`` 后面的 [ n] 标号
            library.object_file_ids << objc_file_id
  
            # 6. 确认 library 的 pod_name 名字
            if line.include?('/Pods/')
              # [ 23] /Users/xxx/ci-jenkins/workspace/xxx-iOS-module/VenomShellProject/osee2unified/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFAutoPurgingImageCache.o)
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
            @object_map[objc_file_id] = of
            # puts "#{objc_file_id} -- #{library_name}"

            # 5. 
            library = @library_map[library_name]
            library ||= Library.new(library_name, 0, [], 0, '')

            # 6.
            library.object_file_ids << objc_file_id
  
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
            @object_map[objc_file_id] = of
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
            object_file = @object_map[object_file_id]
            
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

            # 6. 统计【Object File】总大小
            object_file.size += symbol_size

            # 7. 统计【library/framework】总大小
            library = @library_map[object_file.library]
            library.size += symbol_size if library

            # 8. 统计【segment】总大小
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
          # <<dead>> 	0x00000028	[  2] literal string: com.xxx.audioBook.notifications.start
          # <<dead>> 	0x00000029	[  2] literal string: com.xxx.audioBook.notifications.stoped
          # <<dead>> 	0x0000002A	[  2] literal string: com.xxx.audioBook.notificaitons.loading
          # <<dead>> 	0x0000002A	[  2] literal string: com.xxx.audioBook.notificaitons.palying
          # <<dead>> 	0x0000002D	[  2] literal string: com.xxx.audioBook.notificaitons.paySuccess
          # <<dead>> 	0x00000006	[  2] literal string: appId
          # <<dead>> 	0x00000008	[  2] literal string: fakeURL
          # <<dead>> 	0x00000007	[  2] literal string: 300300
  
          if line =~ %r(^<<dead>>\s+0x(.+?)\s+\[(.+?)\]\w*)
            size = $1.to_i(16)
            file = $2.to_i

            object_file = @object_map[file]
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
