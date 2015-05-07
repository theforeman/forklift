module KatelloDeploy
  class OperatingSystem

    def detect
      begin
        os_family = `uname -s`.chomp.downcase
      rescue Errno::ENOENT
        raise 'OS Family could not be detected'
      end

      case (os_family)
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
