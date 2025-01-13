# rubocop:disable Naming/FileName
# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['LANG'] = 'en_US.UTF-8'
ENV['LC_ALL'] = 'en_US.UTF-8'
ENV['VAGRANT_SERVER_URL'] ||= 'https://vagrantcloud.com/api/v2/vagrant'
VAGRANTFILE_DIR = File.dirname(__FILE__)

require "#{VAGRANTFILE_DIR}/vagrant/lib/forklift"

loader = Forklift::BoxLoader.new("#{VAGRANTFILE_DIR}/vagrant")
loader.load!
distributor = Forklift::BoxDistributor.new(loader.boxes)
distributor.distribute!

# rubocop:enable Naming/FileName
