module Forklift
  module Processors
    module ScriptsProcessor
      def self.process
        return unless File.directory?('scripts')

        Dir.chdir('scripts') do
          run_scripts
        end

        true
      end

      def self.run_scripts
        scripts = Dir.glob('*').select { |e| File.file? e }

        scripts.sort.each do |script|
          system("./#{script}")
        end
      end
    end
  end
end
