#!/usr/bin/env ruby

require 'json'
require 'pp'

routes = JSON.parse(`oc get routes --output json`)

foreman_route = routes['items'].find do |route|
  route['metadata']['labels']['service'] == 'httpd'
end

abort('No Openshift routes found. Was the service deployed?') if foreman_route.nil?

foreman_route = foreman_route['spec']['host']

waiting = 0
output = ''

while waiting < 300
  puts 'Checking if application is up'
  output = `curl https://#{foreman_route} -k 2> /dev/null`
  break if output.include?('users/login')
  waiting += 1
  sleep 1
end

unless output.include?('users/login')
  abort('The main route /users/login not reachable')
end

puts ''
puts 'Checking ping status'
output = JSON.parse(`curl https://#{foreman_route}/katello/api/v2/ping -k 2> /dev/null`)

pp output

if output['status'] == 'FAIL'
  abort('Katello ping API is failing')
end

system("docker run -e FOREMAN_HOSTNAME=#{foreman_route} test-bats")
