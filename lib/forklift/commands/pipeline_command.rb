require 'clamp'

module Forklift
  module Command
    class UpCommand < Clamp::Command
      include Command::Helpers

      parameter "PIPELINE", "Name of the pipeline to run"

      def execute
        pipeline_loader = PipelineLoader.new
        pipeline = pipeline_loader.pipeline(@pipeline)

        unless pipeline
          puts "No pipeline found for #{@pipeline}"
          exit 1
        end

        pipeline.boxes.keys.each do |box|
          execute_command("vagrant up #{box}")
        end
      end

    end

    class DestroyCommand < Clamp::Command
      include Command::Helpers

      parameter "PIPELINE", "Name of the pipeline to destroy"

      def execute
        pipeline_loader = PipelineLoader.new
        pipeline = pipeline_loader.pipeline(@pipeline)
        boxes = pipeline.boxes.keys.join(' ')
        pipeline.boxes.keys.each do |box|
          execute_command("vagrant destroy #{box}")
        end
      end

    end

    class ProvisionCommand < Clamp::Command
      include Command::Helpers

      parameter "PIPELINE", "Name of the pipeline to provision"

      def execute
        pipeline_loader = PipelineLoader.new
        pipeline = pipeline_loader.pipeline(@pipeline)
        boxes = pipeline.boxes.keys.join(' ')
        pipeline.playbooks.each do |playbook|
          success = execute_command("ansible-playbook #{pipeline.location}/#{playbook}")
          exit 1 unless success
        end
      end

    end

    class ListCommand < Clamp::Command
      include Command::Helpers

      def execute
        pipeline_loader = PipelineLoader.new
        max_name_length = pipeline_loader.pipelines.map(&:name).max { |a, b| a.length <=> b.length }.length
        pipeline_loader.pipelines.each do |pipeline|
          puts [pipeline.name, (" " * (max_name_length - pipeline.name.length + 1)), pipeline.description].join(' ')
        end
      end

    end

    class PipelineCommand < Clamp::Command
      subcommand "up", "Bring up the boxes necessary to run a pipeline", UpCommand
      subcommand "destroy", "Destroy the boxes associated a pipeline", DestroyCommand
      subcommand "provision", "Provision the playbooks associated to a pipeline", ProvisionCommand
      subcommand "list", "List pipelines", ListCommand
    end

  end
end
