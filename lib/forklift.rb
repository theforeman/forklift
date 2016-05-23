$LOAD_PATH.unshift File.dirname(__FILE__)

files = Dir[File.dirname(__FILE__) + '/forklift/**/*.rb']
files.uniq.each { |f| require f }

module Forklift
end
