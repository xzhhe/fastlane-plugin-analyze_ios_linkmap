require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    module LinkMap
      class FileHelper
        def self.file_size(file_path)
          return 0 unless File.exist?(file_path)
  
          base = File.basename(file_path)
          return 0 if ['.', '..'].include?(base)
  
          total = 0
          if File.directory?(file_path)
            Dir.glob(File.expand_path('*', file_path)).each do |f|
              # pp f
              total += file_size(f)
            end
          else
            size = File.stat(file_path).size
            total += size
          end
  
          total
        end
  
        def self.format_size(bytes)
          return '0 B' unless bytes
          return '0 B' if bytes.zero?
  
          k = 1024
          suffix = %w[B KB MB GB TB PB EB ZB YB]
          i = (Math.log(bytes) / Math.log(k)).floor
          base = (k ** i).to_f
          num = (bytes / base).round(2)
          "#{num} " + suffix[i]
        end
      end
    end
  end
end