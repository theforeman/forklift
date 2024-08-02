#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'tempfile'

def ansible_variable_json(version_hash)
  foreman_branch = version_hash['foreman'] == 'nightly' ? 'develop' : "#{version_hash['foreman']}-stable"
  katello_branch = version_hash['katello'] == 'nightly' ? 'master' : "KATELLO-#{version_hash['katello']}"
  ansible_options = {
      'katello_repositories_version': version_hash['katello'],
      'foreman_repositories_version': version_hash['foreman'],
      'pulpcore_repositories_version': version_hash['pulpcore'],
      'foreman_installer_options': ["--katello-devel-katello-scm-revision=#{katello_branch}", "--katello-devel-foreman-scm-revision=#{foreman_branch}"]

  }
  ansible_options.to_json
end

def find_version(version_string)
  if version_string.nil?
    $stderr.print("No katello version specified")
    exit -1
  end

  version_file =  "#{__dir__}/../../vagrant/config/versions.yaml"
  versions = YAML.safe_load(File.read(version_file))

  versions['installers'].each do |version|
    if version['katello'] == version_string
      return version
      exit 0
    end
  end

  $stderr.print("Could not find katello version #{version_string}")
  exit -1
end

def write_json_file(json)
  tmpfile = Tempfile.new
  tmpfile.write(json)
  tmpfile.close
  return tmpfile.path
end

def print_message(version_string)
  puts "========================="
  puts "To try out this box:"
  puts "# vagrant box add centos9-katello-#{version_string}-stable.box --name 'katello/katello-devel-#{version_string}-test' "
  puts ""
  puts "Use this box definition:"
  puts "centos9-katello-#{version_string}-stable:"
  puts "  box_name: katello/katello-devel-#{version_string}-test"
  puts "  hostname: centos9-katello-devel-#{version_string}.example.com"
  puts ""
  puts "To publish this box, run:"
  puts "vagrant-upstream cloud publish -d \"katello-devel #{version_string}\" -s \"katello-devel #{version_string}\" katello/katello-devel #{version_string}.0 libvirt centos9-katello-#{version_string}-stable.box"
end

katello_version = ARGV[0]
version_hash = find_version(katello_version)
json = ansible_variable_json(version_hash)
puts "Using configuration: #{json}"
filename = write_json_file(json)

command = "/usr/bin/packer build --var packer_hostname=centos9-katello-#{katello_version}-stable  --var ansible_variables=\"@#{filename}\" centos9-katello-devel-stable.json"
puts "Running: #{command}"
if system(command)
  print_message(katello_version)
else
  puts "Build failed, see output above for more details."
  exit -1
end
