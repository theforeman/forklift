#!/usr/bin/env ruby

require 'clamp'

require File.join(File.dirname(__FILE__), 'lib/forklift')

class MainCommand < Clamp::Command

  subcommand "koji-task", "Create a local repository from a Koji scratch build", Forklift::Command::KojiTaskCommand
  subcommand "local-repo", "Turn a directory into a local repository for use on the system", Forklift::Command::LocalRepoCommand

end

MainCommand.run
