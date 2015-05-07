$LOAD_PATH.unshift File.dirname(__FILE__)

files = Dir[File.dirname(__FILE__) + '/katello_deploy/**/*.rb']
files.uniq.each { |f| require f }

module KatelloDeploy
end
