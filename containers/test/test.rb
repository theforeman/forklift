#!/usr/bin/env ruby

require 'json'
require 'pp'

`oc project foreman`

waiting = 0
while waiting < 90
  routes = JSON.parse(`oc get routes --output json`)
  puts "Routes: #{routes}"

  foreman_route = routes['items'].find do |route|
    route['metadata']['name'] == 'foreman-https'
  end

  puts "Foreman route: #{foreman_route}"
  break if foreman_route
  waiting += 1
end

if foreman_route.nil?
  pods = JSON.parse(`oc get pods --output json`)
  foreman_operator_pod = pods['items'].first['metadata']['name']

  system("oc logs #{foreman_operator_pod}")

  abort('No Openshift routes found. Was the service deployed?')
end

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
  smoke = system("docker run -e FOREMAN_HOSTNAME=#{foreman_route} quay.io/foreman/smoke-tests:latest")

  exit 1 unless smoke
end
