#!/usr/bin/env ruby

test_folder = File.expand_path(File.dirname(__FILE__))
(Dir["#{test_folder}/**/*_test.rb"].to_a + Dir["#{test_folder}/**/*_spec.rb"].to_a).sort.each do |spec|
  require spec
end
