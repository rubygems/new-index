require 'pathname'

class Gem::ListUpdater

  def initialize(dir, source)
    @dir = Pathname.new(dir).expand_path
    @source = URI.parse(source)
    @http = Net::HTTP::Persistent.new(self.class.name)
  end

  def update(file)

  end

  def fetch(names)
    names.each do |name|
      uri = @source_uri + "/api/v2/deps/#{name}"
      Bundler.ui.debug "GET #{uri}"
      Bundler.bundle_path.join("deps/#{name}").open("w") do |f|
        f.write @http.request(uri).body
      end
    end
  end

end

if $0 == __FILE__
  dir = File.expand_path("../../../index", __FILE__)
  Gem::ListUpdater.new(dir, "http://localhost:2000")
end