gem 'puma-rails', :platform => :ruby
gem 'foreman'
gem 'rdoc' # until https://github.com/theforeman/foreman/pull/3632 is merged.
gem 'coffee-script-source', '1.11.1'
gem 'concurrent-ruby', '1.0.3'
gem 'nokogiri', '< 1.7'

if ENV['ENABLE_KATELLO'] == "true"
  gem "katello", :github => "ehelms/katello", :branch => 'openshift-changes'
end

if ENV['ENABLE_FOREMAN_DISCOVERY'] == "true"
  gem "foreman_discovery", :github => "theforeman/foreman_discovery", :branch => 'develop'
end

if ENV['ENABLE_FOREMAN_REMOTE_EXECUTION'] == "true"
  gem 'foreman_remote_execution', :github => 'theforeman/foreman_remote_execution'
end

if ENV['ENABLE_FOREMAN_DOCKER'] == "true"
  gem 'foreman_docker', :github => 'theforeman/foreman-docker'
end

if ENV['ENABLE_FOREMAN_ANSIBLE'] == "true"
  gem 'foreman_ansible', :github => 'theforeman/foreman_ansible'
end

if ENV['ENABLE_FOREMAN_OPENSCAP'] == "true"
  gem 'foreman_openscap', :github => 'theforeman/foreman_openscap'
end

if ENV['ENABLE_FOREMAN_HOOKS'] == "true"
  gem 'foreman_hooks', :github => 'theforeman/foreman_hooks'
end

#gem "foreman_memcache",         :github => "theforeman/foreman_memcache"
#gem "foreman_dhcp_browser",     :github => "theforeman/foreman_dhcp_browser"
#gem 'foreman_bootdisk',         :github => 'theforeman/foreman_bootdisk'
#gem 'foreman_graphite',         :github => 'theforeman/foreman_graphite'
#gem 'foreman_templates',        :github => 'theforeman/foreman_templates'
#gem 'foreman_expire_hosts',     :github => 'theforeman/foreman_expire_hosts'
#gem 'foreman_cockpit',          :github => 'theforeman/foreman_cockpit'
