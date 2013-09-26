require 'rubygems'
$LOAD_PATH.unshift File.expand_path("~/src/bundler/bundler/lib")
require 'bundler/endpoint_specification'

module Bundler
  class DepGroup
    NAME_PATTERN = /\A[0-9a-zA-Z_\-][0-9a-zA-Z_\-\.]*\Z/
    VERSION_PATTERN = /\A[0-9]+(?>\.[0-9a-zA-Z]+)*(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?\Z/

    def initialize(*names)
      @names = names
      @spec_hash = Hash.new{|h,k| h[k] = {} }
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
        next unless name =~ NAME_PATTERN
        File.open("deps/#{name}") do |file|
          file.each_line do |line|
            line.chomp!
            vp, dr = line.split(' ', 2)
            next unless vp =~ VERSION_PATTERN
            deps, reqs = dr.split('|').map{|l| l.split(",") }
            v, p = vp.split("-", 2)
            gv, gp = Gem::Version.new(v), Gem::Platform.new(p)
            gd = deps.map{|d| Gem::Dependency.new(*d.split(":")) } if deps
            s = EndpointSpecification.new(name, gv, gp, gd)

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
