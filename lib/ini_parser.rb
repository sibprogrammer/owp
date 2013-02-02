class IniParser

  def initialize(content)
    @ini_hash = {}

    content.split("\n").each do |line|
      if /^\s*[A-Z\d_]+\s*=.*$/ =~ line
        name, value = line.split('=', 2)
        @ini_hash[name.strip] = value.strip.sub(/^"(.*)"$/, '\1')
      end
    end
  end

  def get(name)
    @ini_hash[name]
  end

end
