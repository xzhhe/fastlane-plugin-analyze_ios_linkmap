describe Fastlane::Actions::AnalyzeIosLinkmapAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The analyze_ios_linkmap plugin is working!")

      Fastlane::Actions::AnalyzeIosLinkmapAction.run(nil)
    end
  end
end
