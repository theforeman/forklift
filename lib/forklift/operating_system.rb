module Forklift
  class OperatingSystem

    SUPPORTED_OS = %w(rhel6 centos6 fedora19 rhel7 centos7).freeze

    def versions
      {
        'rhel6' => '6',
        'rhel7' => '7',
        'centos6' => '6',
        'centos7' => '7',
        'fedora19' => '19'
      }
    end

    def version(os)
      versions[os]
    end

    def distros
      {
        'rhel6' => 'rhel',
        'rhel7' => 'rhel',
        'centos6' => 'centos',
        'centos7' => 'centos',
        'fedora19' => 'fedora'
      }
    end

    def distro(os)
      distros[os]
    end

    def supported?(os)
      return true if SUPPORTED_OS.include?(os)
      raise "OS #{os} is not supported. Must be one of #{SUPPORTED_OS.join(', ')}."
    end

    def detect
      begin
        os_family = `uname -s`.chomp.downcase
      rescue Errno::ENOENT
        raise 'OS Family could not be detected'
      end

      case os_family
      when 'linux'
        detect_linux
      when /(.*bsd$)|(sunos)/
        detect_bsd(os_family)
      end
    end

    private

    def detect_bsd(os_family)
      maj, _min = `uname -r`.split('.')
      os_family + maj
    end

    def detect_linux
      return 'debian' if debian?
      dist, maj, _min = parse_release
      if dist[/Fedora/]
        dist.downcase + maj
      elsif dist[/CentOS/]
        "centos#{maj}"
      elsif dist[/Red\s*Hat\s*Enterprise/]
        "rhel#{maj}"
      end
    end

    def parse_release
      rel = '/etc/system-release'
      release_info = File.read(rel).chomp if File.exist?(rel)
      return 'unknown_linux' if release_info.nil?
      match = release_info.match(/(.*?) release ([^ ]*)/)
      return 'unknown_linux' if match.nil?
      [match[1], match[2].split('.')].flatten
    end

    def debian?
      File.exist?('/etc/debian_version')
    end

  end
end
