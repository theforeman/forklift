module KatelloDeploy
  module Processors
    module InstallerOptionsProcessor
      def self.process(args)
        installer_options = args.fetch(:installer_options, '')
        devel_user = args.fetch(:devel_user, nil)
        deployment_dir = args.fetch(:deployment_dir, nil)

        return installer_options if devel_user.nil?

        directory = deployment_dir || "/home/#{devel_user}"
        "#{installer_options} --user=#{devel_user} --group=#{devel_user} --deployment-dir=#{directory}"
      end
    end
  end
end
