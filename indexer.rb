#!/usr/bin/env ruby

require 'rubygems'

require 'open-uri'

specs = []

%w[specs.4.8 prerelease_specs.4.8].each do |idx|
  unless File.exists? idx
    begin
      open(idx, 'wb+') do |io|
        io << Gem.gunzip(open("http://production.cf.rubygems.org/#{idx}.gz").read)
      end
    rescue
      File.unlink idx
      raise
    end
  end

  specs.concat Marshal.load(File.read(idx))
end

spec_hash = Hash.new { |h,n| h[n] = [] }

specs.each do |n,v,p|
  if p == 'ruby'
    spec_hash[n] << v.to_s
  else
    spec_hash[n] << "#{v.to_s}-#{p}"
  end
end

# names.list is useful for first-stage discovery in mirrors, and also for the
# command line metaphone/hamming distance helpers.
open('names.list', 'w+') { |io| io.puts(*spec_hash.keys) }

# versions.list is useful for second stage discovery in mirrors, and also for
# single-gem command line installations or progressive (unresolved)
# installations. It is also useful for platform gem discovery. In general this
# would be kept up to date similarly to specs.4.8, but maybe a future design
# could split this out by alphanumerics, or use append & checksum semantics in
# order to allow for HTTP Range queries in updates. This would work for
# well incrementals. See read_versions for an example of how this might be
# consumed in a progressive safe way. Periodic complete rewrites for data
# efficiency would generally not affect the system in an adverse manner, and
# could be daily/weekly/etc.
open('versions.list', 'w+') do |io|
  spec_hash.each do |name, versions|
    io.puts "#{name} #{versions.join(",")}"
  end
end

require 'fileutils'
require 'thread'

FileUtils.mkdir_p 'specs'
FileUtils.mkdir_p 'deps'

$print_mutex ||= Mutex.new
$total = specs.size * 2
$count = 0

def progress
  $print_mutex.synchronize do
    $count += 1
    return unless $count % 1000 == 0
    print "\r#{$count}/#{$total} #{(($count/$total.to_f) * 100).to_i} %"
  end
end

require 'net/http/persistent'
http = Net::HTTP::Persistent.new

spec_q = Queue.new
deps_q = Queue.new

# Fetch all the specs, so we can get dependencies. This isn't really required if
# we had the gemcutter DB to hand, but it also serves as an example of how to do
# this. If we modified the rubygems http client code to HTTP transport
# compression, then we could have raw .gemspec files in this kind of filesystem
# layout, and rely on transport compressors (mirrors that care about efficiency
# can obviously precompress in the standard manners).
spec_ts = Array.new(50) do
  Thread.new do
    while nvp = spec_q.pop
      progress

      n, v, p = nvp
      file = "#{n}-#{v}#{'-' + p unless p == 'ruby'}.gemspec"

      if File.exists?("specs/#{file}")
        deps_q << file
        next
      end

      uri = "http://production.cf.rubygems.org/quick/Marshal.4.8/#{file}.rz"
      http.request(URI uri) do |res|
        case res
        when Net::HTTPSuccess
          open("specs/#{file}", "wb+") { |o| o << Gem.inflate(res.body) }
        else
          $stderr.puts "\nFailed download: specs/#{file}"
        end
      end

      deps_q << file
    end
  end
end

specs.each do |nvp|
  spec_q << nvp
end

spec_ts.size.times { spec_q << nil }

# Generate dependency files. These dependency files have a slightly different
# format, as there is currently no good built-in ascii format for
# Gem::Dependency. In order to keep the first order parsing similar to that of
# versions.list, the outer format is `name csv`, and the inner format of csv is
# then `dependency name:requirement1&requirement2`. We will need to ensure that
# there are never any collisions with these characters, or consider moving the
# format to something that will not collide (e.g. non-printable characters). The
# human readable format is convenient for debugging and non-ruby interaction,
# however, so it's a nice to have.
deps_ts = Array.new(50) do
  Thread.new do
    while specfile = deps_q.pop
      progress

      next unless File.exists?("specs/#{specfile}")

      spec = begin
               Marshal.load(File.read("specs/#{specfile}"))
             rescue
               $stderr.puts "\nCorrupt spec: #{specfile}"
               File.unlink("specs/#{specfile}")
               next
             end

      file = "deps/#{spec.name}"

      open(file, "a+") do |io|
        deps = spec.dependencies.select { |d| d.respond_to?(:type) ? d.type == :runtime : true }
        deps.map! { |d| d.kind_of?(Array) ? "#{d.first} #{d[1]}" : "#{d.name}:#{d.requirements_list.join("&")}" }
        reqs = ["ruby", spec.required_ruby_version, "rubygems", spec.required_rubygems_version]
        reqs.map! { |n,r| "#{n}:#{r.requirements.map{|o,v| "#{o} #{v}" }.join("&")}" if r }
        io.puts "#{spec.version.to_s} #{[deps.join(","), reqs.compact.join(",")].join("|")}"
      end
    end
  end
end

until spec_q.empty?
  spec_ts.each { |t| t.join(0.01) }
  sleep 1
end

spec_ts.each { |t| t.join }

deps_ts.size.times { deps_q << nil }

until deps_q.empty?
  deps_ts.each { |t| t.join(0.01) }
  sleep 1
end

deps_ts.each { |t| t.join }

puts
