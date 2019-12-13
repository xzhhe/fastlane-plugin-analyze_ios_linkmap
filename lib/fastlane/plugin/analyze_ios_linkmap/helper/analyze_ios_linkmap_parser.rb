require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    module LinkMap
      require 'pp'
      require 'json'
      require_relative 'linkmap_helper'

      class Parser
        attr_accessor(:object_map, :library_map, :section_map, :segment_map)

        def initialize(options)
          @file_path   = options[:file_path]
          @all_objects = options[:all_objects] || false
          @all_symbols = options[:all_symbols] || false

          unless @file_path
            raise "❌ [Parser] file_path not pass"
          end

          unless File.exist?(@file_path)
            raise "❌ [Parser] file at #{@file_path} not exist"
          end

          @object_map  = {}
          @library_map = {}
          @section_map = {}
          @segment_map = {}

          parse
        end

        #
        # 读取并解析 Linkmap.txt 文件的【每一行】内容
        #
        def parse
          File.foreach(@file_path).with_index do |line, num|
            # begin
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
                  @subparser = :parse_dead_stripped_symbols
                end
              else
                send(@subparser, line)
              end
            # rescue => e
            #   UI.error "Exception on LinkMap file line #{num}:"
            #   # UI.message line
            # end
          end
          # puts "There are #{@section_map.values.map{|value| value[:residual_size]}.inject(:+)} Byte in some section can not be analyze"
        end

        def parse_object_files(line)
          ObjectFile.new(line) do |of, type|
            # 保存解析完成的 ObjectFile
            @object_map[of.index] = of

            # xx.o 没有 Library 的情况
            next if OBJECT_FILE_TYPE_SYSTEM == type #=> 1) system 类型的 xx.o 不创建 Library
            next unless of.library                  #=> 2) xx.o 没有归属的 library

            # 创建/获取 xx.o 归属到的 library
            library = @library_map[of.library]
            library ||= Library.new({
              name: of.library,
              size: of.size,
              object_files: Array.new,
              dead_symbol_size: of.dead_symbol_size
            })

            # 只有【用户】类型的【xx.a】和【xx.framework】, 才可能是 CocoaPods 方式集成, 也才会有 podspec name
            # podspec、subspec
            ## - 1) 没有 subspec
            # /path/to/Pods/BaiduMobAdSDK/BaiduMobAdSDK/BaiduMobAdSDK.framework ==> podspec name: BaiduMobAdSDK
            ## - 2) 有 subspec
            # /path/to/Pods/AlibcSDK/AlibcSDK/Frameworks/UTDID/UTDID.framework  ==> podspec name: AlibcSDK, subspec name: UTDID
            # /path/to/Pods/AlibcSDK/AlibcSDK/Frameworks/AliAuthSDK/AlibabaAuthExt.framework ==> podspec name: AlibcSDK, subspec name: AliAuthSDK
            # /path/to/Pods/AlibcSDK/AlibcSDK/Frameworks/AliAuthSDK/AlibabaAuthSDK.framework ==> podspec name: AlibcSDK, subspec name: AliAuthSDK
            #
            # 结论
            # - 1) /path/to/pods/<Podspec#name>/.../xx.framework 或 xx.a
            # - 2) /path/to/pods/<Podspec#name>/.../<Subspec#name>/xx.framework 或 xx.a ==> <Subspec#name> 不好确定
            #
            if OBJECT_FILE_TYPE_USER_LIBRARY == type
              if line.include?('/Pods/')
                # [ 23] /path/to/App/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFAutoPurgingImageCache.o)
                divstr = line.split('/Pods/').last      #=> AFNetworking/AFNetworking.framework/AFNetworking(AFAutoPurgingImageCache.o)
                podspec_name = divstr.split('/').first  #=> AFNetworking
                library.podspec_name = podspec_name
              else
                library.podspec_name = nil
              end
            end

            # library【追加】位于 `# Object Files` 后面【xx.o 目标文件】的 下标值 [ n]
            library.object_files << of.index

            # 保存/更新 library
            @library_map[of.library] = library
          end
        end

        def parse_sections(line)
          section                   = Section.new(line)
          @section_map[section.key] = section
        end

        def parse_symbols(line)
          symbol = Fastlane::Helper::LinkMap::Symbol.new(line)
          return if symbol.invalid #=> line parse failed

          object_file = @object_map[symbol.file]
          return unless object_file #=> line can not found object file

          # 累加1: 一个 ObjectFile 总大小 (包含 N个 Symbol)
          object_file.add_symbol(symbol)

          # 累加2: 一个 Library 总大小 (包含 N个 ObjectFile)
          library      =  @library_map[object_file.library]
          library.size += symbol.size if library

          # 累加3: 一个 Segment 总大小 (包含 N个 Section)
          ## 找到 当前被解析 symbol 所属的 section
          section = @section_map.detect do |_, sec|
            if sec
              (sec.start_addr...sec.end_addr).include?(symbol.address)
            else
              false
            end
          end #=> [:"__TEXT:__text", #<FastlaneCore::Helper::LinkMap::Section:0x00007fd8e3787eb8 ...>]
          ## 再把 当前被解析 symbol 符号总大小, 累加到
          if section
            key          = section[0] #=> :"__TEXT:__text"
            value        = section[1] #=> #<FastlaneCore::Helper::LinkMap::Section:0x00007fd8e3787eb8 ...>

            segment_name = value.to_segment           #=> 解析出 section 所属的 segment name
            segment      = @segment_map[segment_name] #=> 尝试从 segment map 中, 查找是否有 缓存的 segment 对象

            unless segment
              segment = Segment.new({ name: segment_name, size: symbol.size, residual_size: symbol.size })
            else
              segment.size          += symbol.size
              segment.residual_size += symbol.size
            end

            @segment_map[segment_name] = segment
          end
        end

        def parse_dead_stripped_symbols(line)
          stripped_symbol = DeadStrippedSymbol.new(line)
          return if stripped_symbol.invalid #=> line parse failed

          object_file = @object_map[stripped_symbol.file]
          return unless object_file #=> line can not found object file

          # 累加 一个 ObjectFile 总大小 (包含 N个 Dead Stripped Symbol)
          object_file.dead_symbol_size += stripped_symbol.size

          # 累加 一个 Library 总大小 (包含 N个 ObjectFile)
          library = @library_map[object_file.library]
          return unless library
          library.dead_symbol_size += stripped_symbol.size
        end

        def pretty_json
          return @json_result if @json_result

          @json_result = JSON.pretty_generate(pretty_hash)
          @json_result
        end

        def pretty_hash
          return @hash_result if @hash_result

          # sort object_map[i].ObjectFile.symbols
          @object_map.each do |_, object_file|
            next unless object_file.symbols

            object_file.symbols.sort! do |sym1, sym2|
              sym2.size <=> sym1.size
            end
          end

          # 计算 linkmap.txt 所有的 symbol 总大小
          total_size = @library_map.values.map(&:size).inject(:+)
          total_dead_size = @library_map.values.map(&:dead_symbol_size).inject(:+)

          # sort library_map[i]
          sorted_librarys = @library_map.values.sort do |a, b|
            b.size <=> a.size
          end

          # fixed library_map[i].object_files[i]
          fixed_librarys = sorted_librarys.map { |lib|
            fixed_library = lib.to_hash(@all_objects)

            if @all_objects
              fixed_library[:object_files] = lib.object_files.map { |object_file_index|
                # 修正 object file [1,2,3,...] ==> ["TXVodPlayerStatsCollection.o", "TXVodDownloadManager.o", "TXUGCVideoRecorder.o", ...]
                object_file = object_map[object_file_index]

                # fixed library_map[i].object_files[i].symbols 是否打印每一个 object file 下面 all symbol
                if object_file
                  object_file.to_hash(@all_symbols)
                else
                  nil
                end
              }.compact
            end

            fixed_library
          }

          @hash_result = {
            count: fixed_librarys.count,
            size: total_size,
            format_total_size: Fastlane::Helper::LinkMap::FileHelper.format_size(total_size),
            dead_size: total_dead_size,
            format_dead_size: Fastlane::Helper::LinkMap::FileHelper.format_size(total_dead_size),
            librarys: fixed_librarys
          }
          @hash_result
        end

        def pretty_merge_by_pod_json
          return @merge_json_result if @merge_json_result
          @merge_json_result = JSON.pretty_generate(pretty_merge_by_pod_hash)
          @merge_json_result
        end

        def pretty_merge_by_pod_hash
          return @merge_hash_result if @merge_hash_result

          @merge_hash_result = {
            count: pretty_hash[:count],
            size: pretty_hash[:size],
            format_size: pretty_hash[:format_size],
            dead_size: pretty_hash[:dead_size],
            format_dead_size: pretty_hash[:format_dead_size]
          }

          # 合并 subspec 下的 library
          # AlibcSDK.podspec
          # ------------------------------------------------------------------
          # $ cd /path/to/App/Pods/AlibcSDK/AlibcSDK/Frameworks
          # $ tree -d -L 3
          # .
          # ├── AliAuthSDK
          # │   ├── AlibabaAuthExt.framework
          # │   └── AlibabaAuthSDK.framework
          # ├── AliLinkPartnerSDK
          # │   └── AlibcLinkPartnerSDK.framework
          # ├── AlibcTradeSDK
          # │   ├── AlibcTradeBiz.framework
          # │   └── AlibcTradeSDK.framework
          # ├── BCUserTrack
          # │   └── UTMini.framework
          # ├── UTDID
          # │   └── UTDID.framework
          # ├── mtopSDK
          # │   ├── MtopSDK.framework
          # │   ├── mtopcoreopen.framework
          # │   └── mtopext.framework
          # └── securityGuard
          #     ├── SGAVMP.framework
          #     ├── SGMain.framework
          #     ├── SGMiddleTier.framework
          #     ├── SGSecurityBody.framework
          #     └── SecurityGuardSDK.framework
          #
          pod_hash = Hash.new
          pretty_hash[:librarys].each_with_object(pod_hash) do |lib, hash|
            apod_librarys = hash[lib[:podspec_name]]
            apod_librarys ||= Array.new
            apod_librarys << lib
            hash[lib[:podspec_name]] = apod_librarys
          end

          @merge_hash_result[:pods] = pod_hash
          @merge_hash_result
        end
      end
    end
  end
end
