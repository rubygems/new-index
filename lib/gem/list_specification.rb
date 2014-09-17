class Gem::ListSpecification

  def initialize(name, version, platform, deps, reqs, source)
    @name = name
    @version_str = version
    @platform_str = platform
    @deps = deps
    @reqs = reqs
    @source = source
  end

  def version
    @version ||= Gem::Version.new(@version_str)
  end

  def platform
    @platform ||= Gem::Platform.new(@platform_str)
  end

  def dependencies
  end

  def required_rubygems_version
  end

  def required_ruby_version
  end

  def gem_checksum
  end

end

#   spec = Gem::ListSpecification.new(name, version, platform, deps)
#   reqs.each do |req|
#     spec.send("required_#{req.name}_version", req.requirement)
#   end if reqs
#   spec.source = @source
#   spec.source_uri = @source_uri
# end
#
# def spec(name, version)
# end
#
#   def version_info(line)
#     vp, dr = line.split(' ', 2)
#     return unless vp =~ VERSION_PATTERN
#
#     v, p = vp.split("-", 2)
#     gv, gp = Gem::Version.new(v), Gem::Platform.new(p)
#
#     if dr
#       deps, reqs = dr.split('|').map{|l| l.split(",") }
#       gd = deps.map { |d| dependency_info(d) } if deps
#       gr = reqs.map { |r| dependency_info(r) } if reqs
#     end
#
#     [gv, gp, gd, gr]
#   end
#
#   def dependency_info(string)
#     name, req_str = string.split(":")
#     Gem::Dependency.new(name, req_str.split("&"))
#   end
