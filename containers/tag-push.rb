#!/usr/bin/env ruby

images = `docker images`.split("\n")

images = images.select { |image| image.include?('projgriffin') }
images = images.collect { |image| image.split(' ').first }

images.each do |image|
  quay = "quay.io/foreman/#{image.split("\/").last.gsub(/^foreman-/, '')}"
  system("docker tag #{image} #{quay}")
  system("docker push #{quay}")
end
