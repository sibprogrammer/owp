class IniParser
  
  def initialize(content)
    @ini_hash = {}
    
    content.split("\n").each { |line|
      if /[A-Z]+=.*/ =~ line
        name, value = line.split('=', 2)
        @ini_hash[name] = value.sub(/^"(.*)"$/, '\1')    
      end
    }
  end
  
  def get(name)
    @ini_hash[name]
  end
  
end