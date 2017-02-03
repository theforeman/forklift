$LOAD_PATH.unshift File.dirname(__FILE__)

require "#{File.dirname(__FILE__)}"

files = Dir[File.dirname(__FILE__) + '/**/commands/*.rb']
files.uniq.each { |f| require f }

module Forklift
  module Command
  end
end
