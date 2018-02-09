# rubocop:disable Naming/FileName
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_DIR = File.dirname(__FILE__)

require "#{VAGRANTFILE_DIR}/lib/forklift"

def migrate_boxes!
  old = "#{VAGRANTFILE_DIR}/boxes.yaml"
  new = "#{VAGRANTFILE_DIR}/boxes.d/99-local.yaml"

  return if File.symlink?(old) || !File.exist?(old)

  if File.exist?(new)
    raise "File #{new} already exists, refusing to overwrite. Remove boxes.yaml in favor of boxes.d/99-local.yaml"
  end

  File.rename(old, new)
end

migrate_boxes!
loader = Forklift::BoxLoader.new(VAGRANTFILE_DIR)
loader.load!
distributor = Forklift::BoxDistributor.new(loader.boxes)
distributor.distribute!

# rubocop:enable Naming/FileName
