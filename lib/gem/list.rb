require 'uri'

require_relative 'list_data'
require_relative 'list_specification'
require_relative 'list_updater'

class Gem::List

  def initialize(source, dir)
    @source = URI.parse(source)
    @updater = Gem::ListUpdater.new(@source, dir)
    # @updater.update("versions")
    @data = Gem::ListData.new(dir)
    @fetched = []
  end

  def names
    @updater.update("names")
    @data.names
  end

  def specs(*names)
    ensure_fetched(*names)

    names.map do |name|
      @data.info(name).map do |data|
        Gem::ListSpecification.new(name, *data, @source)
      end
    end.flatten(1)
  end

  def spec(name, version, platform = nil)
    ensure_fetched(name)

    data = @data.info_version(name, version, platform)
    Gem::ListSpecification.new(name, *data, @source) if data
  end

  def inspect
    "#<Gem::List source=#{@source} dir=#{@data.dir}>"
  end

  def to_s
    "gems from #{@source}"
  end

private

  def ensure_fetched(*names)
    return
    unfetched = (names - @fetched)
    @updater.fetch(*unfetched)
    @fetched.push(*names)
  end

end

if $0 == __FILE__
  dir = File.expand_path("../../../index", __FILE__)
  list = Gem::List.new("http://localhost:9292", dir)
  p list
  # p list.specs("rack-markdown", "rack-obama")
  p list.specs("rack-obama")
  # p list.spec("rack", "1.2.0")
  # p list.spec("rack", "1.2.0", "ruby")
  # p list.spec("nokogiri", "1.5.4")
  # p list.spec("nokogiri", "1.5.4", "ruby")
  # p list.spec("nokogiri", "1.5.4", "java")
  p ar = list.spec("rack-obama", "0.1.0")
  p ar.dependencies
  p ar.checksum
  p ar.required_rubygems_version
  p ar.required_ruby_version
  p ar = list.spec("rails", "3.0.0")
  p ar.dependencies
  p ar.checksum
  p ar.required_rubygems_version
  p ar.required_ruby_version
end