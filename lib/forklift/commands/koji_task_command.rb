require 'clamp'

module Forklift
  module Command
    class KojiTaskCommand < Clamp::Command

      option "--task", "TASK", "Koji task ID(s)", :required => true, :multivalued => true

      def execute
        Forklift::Processors::KojiTaskProcessor.process(task_list)
      end

    end
  end
end
