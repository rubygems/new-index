require 'pathname'
require 'net/http/persistent'

class Gem::ListUpdater

  def initialize(source, dir, logger = nil)
    @source = URI(source)
    @dir = Pathname.new(dir).expand_path
    @logger = logger
    @http = Net::HTTP::Persistent.new(self.class.name)

    info = @dir.join("info")
    info.mkpath unless info.directory?
  end

  def update(file)
    update_file(file)
  end

  def fetch(*names)
    names.each do |name|
      update_file File.join("info", name)
    end
  end

private

  def update_file(path)
    uri = URI.join(@source, path)
    logger.debug "GET #{uri}"

    res = @http.request(uri)
    if res.is_a?(Net::HTTPOK)
      @dir.join(path).open("w") { |f| f.write res.body }
    end
  end

  def logger
    @logger ||= begin
      require 'logger'
      Logger.new(STDOUT)
    end
  end

end

if $0 == __FILE__
  dir = File.expand_path("../../../index", __FILE__)
  Gem::ListUpdater.new(dir, "http://localhost:9292")
end