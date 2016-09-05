module Forklift
  module Processors
    module InstallerOptionsProcessor
      def self.process(args)
        installer_options = args.fetch(:installer_options, '')
        devel_user = args.fetch(:devel_user, nil)
        deployment_dir = args.fetch(:deployment_dir, nil)

        return installer_options if devel_user.nil?

        directory = deployment_dir || "/home/#{devel_user}"
        "#{installer_options} --katello-devel-user=#{devel_user}"\
        " --certs-group=#{devel_user} --katello-deployment-dir=#{directory} --disable-system-checks"
      end
    end
  end
end
