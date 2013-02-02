# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def translate(key, options = {})
    I18n.translate(key, options)
  end
  alias :t :translate

  def tjs(key, options = {})
    escape_javascript t(key, options)
  end

  def imenu_link_to(title, options = {}, icon = '')
    icon = '<img alt="" src="' + base_url + icon + ' " />' if !icon.empty?
    title = icon + '<span class="name">' + h(title) + '</span><span class="arrow"></span>'
    '<li class="menu">' + link_to(title, options) + '</li>'
  end

  def external_auth?
    AppConfig.ldap.enabled
  end

  def local_datetime(datetime)
    datetime.localtime.strftime("%Y.%m.%d %H:%M:%S")
  end

  def base_url
    ActionController::Base.relative_url_root
  end

  def get_diskspace_mb(limit)
    return 0 if limit.blank?
    limit = limit.include?(':') ? limit.split(":").last : limit
    return 0 if ('unlimited' == limit)

    case limit[-1,1]
      when 'K' then limit = limit.to_f
      when 'M' then limit = limit.to_f * 1024
      when 'G' then limit = limit.to_f * 1024 * 1024
    end

    return 0 if ((2 ** 31 - 1) == limit.to_i || (2 ** 63 - 1) == limit.to_i)

    (limit.to_f / 1024).to_i
  end

  def get_ram_mb(limit)
    return 0 if limit.blank?
    limit = limit.include?(':') ? limit.split(":").last : limit
    return 0 if ('unlimited' == limit)

    units = /[BKMGP]$/.match(limit.upcase) ? limit[-1,1].upcase : 'B'
    limit = limit.to_f

    case units
      when 'B' then limit /= 1024 * 1024
      when 'K' then limit /= 1024
      when 'P' then limit /= 256
      when 'G' then limit *= 1024
    end

    return 0 if ((2 ** 31 - 1) == limit.to_i || (2 ** 63 - 1) == limit.to_i)

    limit.to_i
  end

end
