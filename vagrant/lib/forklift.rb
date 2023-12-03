# frozen_string_literal: true

$LOAD_PATH.unshift __dir__

files = Dir["#{__dir__}/forklift/**/*.rb"]
files.uniq.each { |f| require f }

module Forklift
end
