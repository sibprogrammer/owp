namespace :translate do

  desc "Check for missed keys"
  task :missed => :environment do
    default_locale = I18n.default_locale.to_s
    locale = ENV['LOCALE']

    puts "Comparision of #{default_locale} locale with #{locale}"

    default_locale_keys = get_locale_key(default_locale)
    puts "Default locale #{default_locale} contains: #{default_locale_keys.size} keys."
    locale_keys = get_locale_key(locale)
    puts "Locale #{locale} contains: #{locale_keys.size} keys."

    missed_keys = default_locale_keys - locale_keys
    if !missed_keys.empty?
      puts "Missed #{missed_keys.size} keys:"
      puts "\t" + missed_keys.sort.join("\n\t")
    end

    unknown_keys = locale_keys - default_locale_keys
    if !unknown_keys.empty?
      puts "Unknown (obsoleted) #{unknown_keys.size} keys:"
      puts "\t" + unknown_keys.sort.join("\n\t")
    end

    exit 2 if !missed_keys.empty?
  end

  private

  def flat_keys(hash, keys = [], prefix = '')
    prefix << "." unless prefix.blank?

    hash.each do |key, value|
      if value.is_a?(Hash)
        keys + flat_keys(value, keys, prefix + key)
      else
        keys << (prefix + key)
      end
    end

    return keys
  end

  def get_locale_key(code)
    locale_hash = YAML::load(File.open(File.join("config", "locales", "#{code}.yml")))[code]
    flat_keys(locale_hash)
  end

end
