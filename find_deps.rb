require_relative 'dep_group.rb'

puts "Finding deps for #{ARGV[0]}..."
dg = Bundler::DepGroup.new(ARGV[0].dup)
p dg.specs
p dg.specs[ARGV[0]][ARGV[1]]
