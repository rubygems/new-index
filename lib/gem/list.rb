require 'uri'

require_relative 'list_data'
require_relative 'list_specification'

class Gem::List

  def initialize(source, dir)
    @source = URI.parse(source)
    @list_data = Gem::ListData.new(dir)
  end

  def specs(*names)
    names.map do |name|
      @list_data.info(name).map do |data|
        Gem::ListSpecification.new(name, *data, @source)
      end
    end.flatten(1)
  end

  def spec(name, version, platform = nil)
    data = @list_data.info_version(name, version, platform)
    Gem::ListSpecification.new(name, *data, @source) if data
  end

  def inspect
    "#<Gem::List source=#{@source} dir=#{@list_data.dir}>"
  end

  def to_s
    "gems from #{@source}"
  end

end

if $0 == __FILE__
  dir = File.expand_path("../../../index", __FILE__)
  list = Gem::List.new("https://rubygems.org", dir)
  p list
  # p list.specs("rack-markdown", "rack-obama")
  # p list.specs("rack")
  # p list.spec("rack", "1.2.0")
  # p list.spec("rack", "1.2.0", "ruby")
  # p list.spec("nokogiri", "1.5.4")
  # p list.spec("nokogiri", "1.5.4", "ruby")
  # p list.spec("nokogiri", "1.5.4", "java")
  p ar=list.spec("activerecord", "4.1.2")
  p ar.dependencies
  p ar.gem_checksum
  p ar.required_rubygems_version.to_s
  p ar.required_ruby_version.to_s
end