# rubocop:disable Naming/FileName
# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['LANG'] = 'en_US.UTF-8'
VAGRANTFILE_DIR = File.dirname(__FILE__)

require "#{VAGRANTFILE_DIR}/vagrant/lib/forklift"

def migrate_boxes!
  old = "#{VAGRANTFILE_DIR}/boxes.d/99-local.yaml"
  new = "#{VAGRANTFILE_DIR}/vagrant/boxes.d/99-local.yaml"

  return if File.symlink?(old) || !File.exist?(old)

  if File.exist?(new)
    raise "File #{new} already exists, refusing to overwrite. Remove boxes.d/99-local.yaml in favor of vagrant/boxes.d/99-local.yaml"
  end

  File.rename(old, new)
end

def migrate_settings!
  old = "#{VAGRANTFILE_DIR}/settings.yaml"
  new = "#{VAGRANTFILE_DIR}/vagrant/settings.yaml"

  return if !File.exist?(old)

  if File.exist?(new)
    raise "File #{new} already exists, refusing to overwrite. Remove settings.yaml in favor of vagrant/settings.yaml"
  end

  File.rename(old, new)
end

migrate_boxes!
migrate_settings!
loader = Forklift::BoxLoader.new("#{VAGRANTFILE_DIR}/vagrant")
loader.load!
distributor = Forklift::BoxDistributor.new(loader.boxes)
distributor.distribute!

# rubocop:enable Naming/FileName
