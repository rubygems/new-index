require 'rubygems'
$LOAD_PATH.unshift File.expand_path("~/src/bundler/bundler/lib")
require 'bundler/lazy_specification'

module Bundler
  class DepGroup
    NAME_PATTERN = /\A[a-z0-9_\-][a-z0-9_\-\.]*\Z/i

    def initialize(source, *names)
      @names = names
      @spec_hash = Hash.new{|h,k| h[k] = {} }
      @source = source
    end

    def specs
      @specs ||= create_specs
    end

    def create_specs
      fetch_specs
      parse_specs
    end

    def fetch_specs
      # nothing yet
    end

    def parse_specs
      @names.each do |name|
        File.open("deps/#{name}") do |file|
          file.each_line do |line|
            line.chomp!
            next unless line =~ NAME_PATTERN
            vp, dr = line.split(' ', 2)
            deps, reqs = dr.split('|').map{|l| l.split(",") }
            v, p = vp.split("-", 2)
            gv, gp = Gem::Version.new(v), Gem::Platform.new(p)
            s = LazySpecification.new(name, gv, gp, @source)

            deps.each do |d|
              s.dependencies << Gem::Dependency.new(*d.split(":"))
            end if deps

            reqs.each do |r|
              n,v = r.split(":")
              case n
              when "rubygems"
                s.required_rubygems_version = Gem::Requirement.new(v)
              when "ruby"
                s.required_ruby_version = Gem::Requirement.new(v)
              end
            end if reqs

            @spec_hash[name][vp] = s
          end
        end
      end
      @spec_hash
    end

  end
end
