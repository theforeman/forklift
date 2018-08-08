#!/usr/bin/env ruby

require 'json'
require 'pp'

`oc project foreman`

routes = JSON.parse(`oc get routes --output json`)

foreman_route = routes['items'].find do |route|
  route['metadata']['name'] == 'foreman-https'
end

abort('No Openshift routes found. Was the service deployed?') if foreman_route.nil?

foreman_route = foreman_route['spec']['host']
puts "Foreman host at #{foreman_route}"

waiting = 0
output = ''
up = false

while waiting < 900
  puts ''
  puts 'Checking ping status'
  begin
    pp "curl https://#{foreman_route}/katello/api/v2/ping -k"
    output = JSON.parse(`curl https://#{foreman_route}/katello/api/v2/ping -k 2> /dev/null`)
    pp output
    up = true
    break if output['services'].all? { |service, status| status['status'] == 'ok' }
  rescue
    pp output
  end

  waiting += 10
  sleep 10
end

system("oc get pods")
abort("Ping failed") unless up

if ARGV[0] == '--smoke'
  Dir.chdir "./foreman-ansible-modules/"
  system("yum install gcc python-devel -y")
  system("make test-setup")
  #system("ansible fixtures -m pip -a 'name=git+https://github.com/SatelliteQE/nailgun.git@master#egg=nailgun'"
  #system("ansible tests -m pip -a 'name=git+https://github.com/SatelliteQE/nailgun.git@master#egg=nailgun'"
  MODULES = [
    'activation_key',
    'compute_profile',
    'content_view',
    'domain',
    'global_parameter',
    'job_template',
    'location',
    'lifecycle_environment',
    'operating_system',
    'organization',
    'os_default_template',
    'product',
    'provisioning_template',
    'ptable',
    'redhat_manifest',
    'repository',
    'repository_sync',
    'setting',
    'sync_plan',
  ]
  MODULES.each do |mod|
    smoke = system("ansible-playbook -e foreman_server_url=https://#{foreman_route} test/test_playbooks/#{mod}.yml")
    exit 1 unless smoke
  end
end
