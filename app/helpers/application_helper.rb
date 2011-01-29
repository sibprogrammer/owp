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
    icon = '<img alt="" src="' + icon + ' " />' if !icon.empty?
    title = icon + '<span class="name">' + h(title) + '</span><span class="arrow"></span>'
    '<li class="menu">' + link_to(title, options) + '</li>'
  end

  def external_auth?
    AppConfig.ldap.enabled
  end

  def local_datetime(datetime)
    datetime.localtime.strftime("%Y.%m.%d %H:%M:%S")
  end
  
end
