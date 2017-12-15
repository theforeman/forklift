# rubocop:disable Naming/FileName
# -*- mode: ruby -*-
# vi: set ft=ruby :

require "#{File.dirname(__FILE__)}/lib/forklift"

loader = Forklift::BoxLoader.new
loader.load
distributor = Forklift::BoxDistributor.new(loader.boxes)
distributor.distribute

# rubocop:enable Naming/FileName
