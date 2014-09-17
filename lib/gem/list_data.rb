require 'pathname'

class Gem::ListData
  attr_reader :dir

  def initialize(dir)
    @dir = Pathname.new(dir).expand_path
  end

  def names
    dir.join("names").read.lines.map!{|l| l.chomp! }
  end

  def versions
    versions = Hash.new { |h,n| h[n] = [] }

    list_lines("versions").each do |line|
      name, vs = parse_versions(line)
      versions[name].concat(vs)
    end

    versions
  end

  def info(name)
    list_lines("info", name).map do |line|
      parse_info(line)
    end
  end

  def info_version(name, *version)
    version.pop if version.last == "ruby"

    pattern = version.compact.join("-")
    matcher = /\A#{Regexp.escape(pattern)} / unless pattern.empty?

    list_lines("info", name).each do |line|
      return parse_info(line) if line =~ matcher
    end if matcher

    nil
  end

private

  def list_lines(*path)
    lines = dir.join(*path).read.lines
    header = lines.shift until header == "---\n"
    lines
  end

  def parse_versions(line)
    line.chomp!
    name, vs = line.split(' ', 2)
    vs = vs.split(',')
    vs.map! { |v| v.split('-', 2) }
    [name, vs]
  end

  def parse_info(line)
    line.chomp!
    vp, dr = line.split(' ', 2)
    version, platform = vp.split("-", 2)

    d, r = dr.split('|').map{|l| l.split(",") } if dr
    deps = d.map{|h, d| parse_dependency(d) } if d
    reqs = r.map { |r| parse_dependency(r) } if r

    [version, platform, deps, reqs]
  end

  def parse_dependency(string)
    dep = string.split(":")
    dep[-1] = dep[-1].split("&")
    dep
  end

end

if __FILE__ == $0
  dir = File.expand_path("../../../index", __FILE__)
  # list = Gem::List.new(dir)
  # p names = list.names[0..10]
  # p versions = list.versions.values_at(*names)
  # p list.info("rails").find{|a| a[0] == "4.1.0" }
  p list.info("rails", "4.1.0")
  p list.info("rails", "4.8")
end