reqs_hash = Hash.new { |h, n| h[n] = Hash.new { |rh, v| rh[v] = {:deps => [], :reqs => []} } }

name = 'nokogiri'

open("deps/#{name}") do |io|
  io.each_line do |line|
    line.chomp!
    vp, drs = line.split(' ', 2)
    deps, reqvs = drs.split('|')

    if deps
      deps = deps.split(',')
      deps.map! do |str|
        dname, reqs = str.split(':', 2)
        reqs = reqs.split('&')
        Gem::Dependency.new(dname, reqs)
      end
      reqs_hash[name][vp][:deps].concat deps
    end

    if reqvs
      reqvs = reqvs.split(',')
      reqvs.map! do |str|
        rname, reqs = str.split(':', 2)
        reqs = reqs.split('&')
        Gem::Dependency.new(rname, reqs)
      end
      reqs_hash[name][vp][:reqs].concat reqvs
    end
  end
end

p reqs_hash
