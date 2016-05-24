#!/usr/bin/env ruby

require 'clamp'

require File.join(File.dirname(__FILE__), 'lib/forklift')

class MainCommand < Clamp::Command

  subcommand "koji-task", "Create a local repository from a Koji scratch build", Forklift::Command::KojiTaskCommand

end

MainCommand.run
