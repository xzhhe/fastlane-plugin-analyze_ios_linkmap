require 'pp'

# ❤️ 🧡 💛 💚 💙 💜 🖤 💔

describe Fastlane::Actions::AnalyzeIosLinkmapAction do
  describe '#AnalyzeIosLinkmapAction' do
    it 'run 1' do
      Fastlane::Actions::AnalyzeIosLinkmapAction.run(
        filepath: '/Users/xiongzenghui/Desktop/osee2unifiedRelease-LinkMap-normal-arm64.txt',
        search_symbol: 'TDATEvo'
      )
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_SEARCH_SYMBOL]
    end

    it 'run 2' do
      Fastlane::Actions::AnalyzeIosLinkmapAction.run(
        filepath: '/Users/xiongzenghui/collect_rubygems/fastlane-plugins/fastlane-plugin-analyze_ios_linkmap/spec/demo-LinkMap.txt'
      )
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARED_HASH]
      pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARED_JSON]
    end
  end

  describe '#analyze_ios_linkmap_helper' do
    it 'parse' do
      # path = '/Users/xiongzenghui/collect_rubygems/fastlane-plugins/fastlane-plugin-analyze_ios_linkmap/spec/demo-LinkMap.txt'
      path = '/Users/xiongzenghui/Desktop/xxx-LinkMap-normal-arm64.txt'

      parser = Fastlane::Helper::LinkMap::Parser.new(path)
      
      # puts '🔵' * 50
      # pp parser.object_map
      
      # puts '🔵' * 50
      # pp parser.library_map
      
      # puts '🔵' * 50
      # pp parser.segment_map
      # pp parser.segment_map.count

      # puts '🔵' * 50
      # pp parser.result

      # puts '🔵' * 50
      pp parser.pretty_hash

      puts '🔵' * 50
      # pp parser.pretty_json
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
