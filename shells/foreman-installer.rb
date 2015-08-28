#!/usr/bin/env ruby
require 'rubygems'
require 'kafo'

# where to find scenarios
CONFIG_DIR = '/etc/foreman/installer-scenarios.d/'

# Run the install
@result = Kafo::KafoConfigure.run

# handle exit code when help was invoked or installer ended with '2' (success in puppet)
if @result.nil? || (!@result.config.app[:detailed_exitcodes] && @result.exit_code == 2)
  exit(0)
else
  exit(@result.exit_code)
end
