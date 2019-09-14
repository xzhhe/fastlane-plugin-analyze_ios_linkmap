require 'pp'

# ❤️ 🧡 💛 💚 💙 💜 🖤 💔

describe Fastlane::Actions::AnalyzeIosLinkmapAction do
  describe '#AnalyzeIosLinkmapAction' do
    it 'run 1' do
      Fastlane::Actions::AnalyzeIosLinkmapAction.run(
        filepath: '/Users/xiongzenghui/collect_rubygems/fastlane-plugins/fastlane-plugin-analyze_ios_linkmap/spec/demo-LinkMap.txt'
      )
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_HASH]
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_JSON]
    end

    it 'run 2' do
      Fastlane::Actions::AnalyzeIosLinkmapAction.run(
        filepath: '/Users/xiongzenghui/Desktop/osee2unifiedRelease-LinkMap-normal-arm64.txt',
        search_symbol: 'TDATEvo'
      )
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_SEARCH_SYMBOL]
    end

    it 'run 3' do
      Fastlane::Actions::AnalyzeIosLinkmapAction.run(
        filepath: '/Users/xiongzenghui/Desktop/mr_linkmap.txt',
        all_symbols: false,
        merge_by_pod: true
      )
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_HASH]
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_JSON]
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_MERGE_HASH]
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_MERGE_JSON]
    end
  end

  describe '#analyze_ios_linkmap_helper' do
    it 'parse' do
      path = '/Users/xiongzenghui/Desktop/mr_linkmap.txt'

      parser = Fastlane::Helper::LinkMap::Parser.new(
        {
          filepath: path,
          all_symbols: false
        })
      
      puts '🔵' * 50
      pp parser.object_map
      
      puts '🔵' * 50
      pp parser.library_map
      
      puts '🔵' * 50
      pp parser.segment_map
      pp parser.segment_map.count

      puts '🔵' * 50
      pp parser.pretty_hash

      puts '🔵' * 50
      pp parser.pretty_json

      puts '🔵' * 50
      pp parser.pretty_merge_by_pod_hash

      puts '🔵' * 50
      pp parser.pretty_merge_by_pod_json
    end


    it 'parse_object_files' do
      # expect(Fastlane::UI).to receive(:message).with("The analyze_ios_linkmap plugin is working!")

      parser = Fastlane::Helper::LinkMap::Parser.new('spec/demo-LinkMap.txt')
      
      puts ' ❤️' * 50
      line = "[ 24] /Users/xx/workspace/Demo/Pods/AFNetworking/AFNetworking.framework/AFNetworking(AFAutoPurgingImageCache.o)"
      parser.parse_object_files(line)
      pp parser.objects_map
      puts '-' * 50
      pp parser.library_map

      puts ' 🧡' * 50
      line = "[ 39] /Users/xx/workspace/Demo/Pods/BangcleCryptoTool/BangcleCryptoTool/libs/libbangcle_crypto_tool.a(aes.o)"
      parser.parse_object_files(line)
      pp parser.objects_map
      puts '-' * 50
      pp parser.library_map

      puts '💛' * 50
      line = "[ 57] /Users/xiongzenghui/Library/Developer/Xcode/DerivedData/Demo-flaernxtbxiuwbapfnbgghocjkde/Build/Intermediates.noindex/Demo.build/Debug-iphonesimulator/Demo.build/Objects-normal/x86_64/main.o"
      parser.parse_object_files(line)
      pp parser.objects_map
      puts '-' * 50
      pp parser.library_map
    end

    it 'parse_sections' do
      parser = Fastlane::Helper::LinkMap::Parser.new('spec/demo-LinkMap.txt')
      line = "0x1000048A0	0x055656A8	__TEXT	  __text"
      parser.parse_sections(line)
      pp parser.segment_map
    end
  end
end
