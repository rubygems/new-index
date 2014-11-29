class Gem::ListSpecification
  attr_reader :name, :version, :platform, :dependencies, :source,
    :required_rubygems_version, :required_ruby_version, :checksum

  def initialize(name, version, platform, deps, metadata, source)
    @name = name
    @version = Gem::Version.new(version)
    @platform = Gem::Platform.new(platform)
    @dependencies = (deps || []).map { |d| Gem::Dependency.new(*d) }
    @source = source

    parse_metadata(metadata)
  end

private

  def parse_metadata(data)
    data.each do |k, v|
      case k
      when "checksum"
        @checksum = v.last
      when "rubygems"
        @required_rubygems_version = Gem::Requirement.new(v) if v
      when "ruby"
        @required_ruby_version = Gem::Requirement.new(v) if v
      end
    end
  end

end
