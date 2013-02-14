reqs_hash = Hash.new { |h, n| h[n] = Hash.new { |rh, v| rh[v] = [] } }

name = 'rails'

open("deps/#{name}") do |io|
  io.each_line do |line|
    line.chomp!
    version, deps = line.split(' ', 2)
    deps = deps.split(',')
    deps.map! do |str|
      name, reqs = str.split(':', 2)
      reqs = reqs.split('&')
      Gem::Dependency.new(name, reqs)
    end
    reqs_hash[name][version].concat deps
  end
end
