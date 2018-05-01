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
    output = JSON.parse(`curl https://#{foreman_route}/katello/api/v2/ping -k 2> /dev/null`)
    pp output
    up = true
    break if output['services'].all? { |service, status| status['status'] == 'ok' }
  rescue
  end

  waiting += 10
  sleep 10
end

system("oc get pods")
abort("Ping failed") unless up

if ARGV[0] == '--smoke'
  smoke = system("docker run -e FOREMAN_HOSTNAME=#{foreman_route} projgriffin/test-bats:latest")

  exit 1 unless smoke
end
