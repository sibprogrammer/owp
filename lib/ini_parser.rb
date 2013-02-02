class IniParser

  def initialize(content)
    @ini_hash = {}

    content.split("\n").each { |line|
      if /^\s*[A-Z\d_]+\s*=.*$/ =~ line
        name, value = line.split('=', 2)
        @ini_hash[name.strip] = value.strip.sub(/^"(.*)"$/, '\1')
      end
    }
  end

  def get(name)
    @ini_hash[name]
  end

  def get_mb(name)
    limit = get(name)
    return 0 if limit.blank?
    limit = limit.include?(':') ? limit.split(":").last : limit
    return 0 if ('unlimited' == limit)

    limit = limit.to_i if limit.ends_with?('K')
    limit = (limit.to_f * 1024).to_i if limit.ends_with?('M')
    limit = (limit.to_f * 1024 * 1024).to_i if limit.ends_with?('G')

    return 0 if ((2 ** 31 - 1) == limit.to_i || (2 ** 63 - 1) == limit.to_i)

    limit.to_i / 1024
  end

end
