if Gem.loaded_specs['vagrant']
  require 'vagrant/util/deep_merge'
else
  require 'deep_merge'
end

def deep_merge(myself, other)
  if Gem.loaded_specs['vagrant']
    Vagrant::Util::DeepMerge.deep_merge(myself, other)
  else
    myself.deep_merge(other)
  end
end
