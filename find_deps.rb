$LOAD_PATH.unshift File.expand_path("~/src/bundler/bundler/lib")
require 'bundler'

puts "Finding deps for #{ARGV[0]}..."
ds = Bundler::DepSpecs.new("source", [ARGV[0].dup])
p ds.spec_index
p ds.spec_index.search Gem::Dependency.new(ARGV[0], ARGV[1])
