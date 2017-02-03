module Forklift
  module Command
    module Helpers

      def execute_command(command)
        process = IO.popen("#{command} 2>&1") do |io|
          while line = io.gets
            line.chomp!
            puts line
          end
          io.close
          $?.success?
        end
      end

    end
  end
end
