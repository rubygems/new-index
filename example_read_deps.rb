reqs_hash = Hash.new { |h, n| h[n] = Hash.new { |rh, v| rh[v] = {:deps => [], :reqs => []} } }

name = 'rails'

open("deps/#{name}") do |io|
  io.each_line do |line|
    line.chomp!
    version, drs = line.split(' ', 2)
    deps, reqvs = drs.split('|', 2)
    deps = deps.split(',')
    deps.map! do |str|
      name, reqs = str.split(':', 2)
      reqs = reqs.split('&')
      Gem::Dependency.new(name, reqs)
    end
    reqs_hash[name][version][:deps].concat deps
    next unless reqvs
    p reqvs
    reqvs = reqvs.split(',')
    reqvs.map! do |str|
      name, reqs = str.split(':', 2)
      reqs = reqs.split('&')
      Gem::Dependency.new(name, reqs)
    end
    reqs_hash[name][version][:reqs].concat reqs
  end
end

p reqs_hash.keys
