require 'pp'

# DEBUG=true bundle exec rspec spec/analyze_ios_linkmap_action_spec.rb:57 > /Users/xiongzenghui/Desktop/result.rb

describe Fastlane::Actions::AnalyzeIosLinkmapAction do
  describe '#analyze_ios_linkmap_helper' do
    it 'parse_symbol' do
      path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
      line = '0x10318DD5C	0x0000024C	[9482] -[ZHQuestionNavigationBarFooterView bindNaviFooterViewWith:]'
      puts Fastlane::Helper::LinkMap::Symbol.new(line)

      line = '0x1031D4998	0x00000008	[9540] _$s10ZHModuleQA28AddQuestionBarViewControllerC27$__lazy_storage_$_tipsLabel33_3457F60F807DB9D2C946ABA5C1CE2A27LLSo7UILabelCSgvpfi'
      puts Fastlane::Helper::LinkMap::Symbol.new(line)
    end

    it 'parse_dead_stripped_symbol' do
      line = '<<dead>> 	0x00000008	[ 26] ___destroy_helper_block_e8_32s'
      puts Fastlane::Helper::LinkMap::DeadStrippedSymbol.new(line)
    end

    it 'parse_sections' do
      line = '0x105569F48	0x000090E4	__TEXT	  __stubs'
      puts Fastlane::Helper::LinkMap::Section.new(line).name
    end

    it 'parse_object_file-user' do
      line = '[  5] /Users/xiongzenghui/App/Pods/BangcleCryptoTool/BangcleCryptoTool/libs/libbangcle_crypto_tool.a(aes.o)'
      Fastlane::Helper::LinkMap::ObjectFile.new(line)
      line = '[ 23] /Users/xiongzenghui/App/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFAutoPurgingImageCache.o)'
      Fastlane::Helper::LinkMap::ObjectFile.new(line)
    end

    it 'parse_object_file-others' do
      # [  2] /path/to/App/AdHoc-iphoneos/Demo.build/Objects-normal/arm64/main.o
      # [  3] /path/to/App/AdHoc-iphoneos/Demo.build/Objects-normal/arm64/ZHUIAutoTest.o
      # [  4] /path/to/App/AdHoc-iphoneos/Demo.build/Objects-normal/arm64/swift.o
      line = '[  3] /path/to/Release-iphoneos/CrashDemo.build/Objects-normal/arm64/main.o'
      Fastlane::Helper::LinkMap::ObjectFile.new(line)

      line = '[100] /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.3.sdk/System/Library/Frameworks/UIKit.framework/UIKit.tbd'
      Fastlane::Helper::LinkMap::ObjectFile.new(line)

      line = '[9742] /path/to/Pods/du.framework/du'
      Fastlane::Helper::LinkMap::ObjectFile.new(line)

      line = '[8659] /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphoneos/libswiftDispatch.dylib'
      Fastlane::Helper::LinkMap::ObjectFile.new(line)
    end

    it 'parse_object_file-system' do
      line = '[  0] linker synthesized'
      Fastlane::Helper::LinkMap::ObjectFile.new(line)
      line = '[  1] dtrace'
      Fastlane::Helper::LinkMap::ObjectFile.new(line)
    end

    it 'parse - 01' do
      path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
      parser = Fastlane::Helper::LinkMap::Parser.new(
        {
          file_path: path,
          all_objects: false,
          all_symbols: false
        }
      )
      puts parser.generate_json
    end

    it 'parse - 02' do
      path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
      parser = Fastlane::Helper::LinkMap::Parser.new(
        {
          file_path: path,
          all_objects: true,
          all_symbols: false
        }
      )
      puts parser.generate_json
    end

    it 'parse - 03' do
      path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
      parser = Fastlane::Helper::LinkMap::Parser.new(
        {
          file_path: path,
          all_objects: true,
          all_symbols: true
        }
      )
      puts parser.generate_json
    end

    it 'parse-merge_by_pod' do
      path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
      parser = Fastlane::Helper::LinkMap::Parser.new(
        {
          file_path: path,
          all_objects: false,
          all_symbols: false
        }
      )
      puts parser.generate_merge_by_pod_json
    end
  end

  describe '#AnalyzeIosLinkmapAction' do
    it 'run 1' do
      path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
      Fastlane::Actions::AnalyzeIosLinkmapAction.run( file_path: path )
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_HASH]
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_JSON]
    end

    it 'run 2' do
      path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
      Fastlane::Actions::AnalyzeIosLinkmapAction.run(
        file_path: path,
        all_objects: true
      )
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_HASH]
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_JSON]
    end

    it 'run 3' do
      path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
      Fastlane::Actions::AnalyzeIosLinkmapAction.run(
        file_path: path,
        all_objects: true,
        all_symbols: true
      )
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_HASH]
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_JSON]
    end

    it 'run 4' do
      path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
      Fastlane::Actions::AnalyzeIosLinkmapAction.run(
        file_path: path,
        all_objects: false,
        all_symbols: false,
        merge_by_pod: true
      )
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_HASH]
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_JSON]
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_MERGE_HASH]
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_MERGE_JSON]
    end

    it 'run 5' do
      path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
      Fastlane::Actions::AnalyzeIosLinkmapAction.run(
        file_path: path,
        search_symbol: 'TDATEvo'
      )
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_SEARCH_SYMBOL]
    end
  end
end
