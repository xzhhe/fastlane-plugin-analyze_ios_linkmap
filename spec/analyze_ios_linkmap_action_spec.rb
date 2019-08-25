require 'pp'

# ❤️ 🧡 💛 💚 💙 💜 🖤 💔

describe Fastlane::Actions::AnalyzeIosLinkmapAction do
  describe '#AnalyzeIosLinkmapAction' do
    it 'run' do
      # Fastlane::Actions::AnalyzeIosLinkmapAction.run(nil)

    end
  end

  describe '#analyze_ios_linkmap_helper' do
    it 'parse' do
      parser = Fastlane::Helper::LinkMap::Parser.new('/Users/xiongzenghui/collect_rubygems/fastlane-plugins/fastlane-plugin-analyze_ios_linkmap/spec/demo-LinkMap.txt')
      parser.parse
      
      # puts '🔵' * 50
      # pp parser.objects_map
      
      # puts '🔵' * 50
      # pp parser.library_map
      
      puts '🔵' * 50
      pp parser.segment_map
      # pp parser.segment_map.count
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
      # expect(Fastlane::UI).to receive(:message).with("The analyze_ios_linkmap plugin is working!")
      # Fastlane::Actions::AnalyzeIosLinkmapAction.run(nil)

      parser = Fastlane::Helper::LinkMap::Parser.new('spec/demo-LinkMap.txt')

      line = "0x1000048A0	0x055656A8	__TEXT	  __text"
      parser.parse_sections(line)
      pp parser.segment_map
    end
  end
end
