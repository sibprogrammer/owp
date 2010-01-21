require 'net/ftp'

class OsTemplate < ActiveRecord::Base
  belongs_to :hardware_server
  
  def self.get_available_official
    get_available(AppConfig.os_templates.mirror.path + '/precreated/')
  end
  
  def self.get_available_contributed
    get_available(AppConfig.os_templates.mirror.path + '/precreated/contrib/')
  end
  
  def self.install_official(hardware_server, name)
    self.download(hardware_server, AppConfig.os_templates.mirror.path + '/precreated/', name)
  end
  
  def self.install_contributed(hardware_server, name)
    self.download(hardware_server, AppConfig.os_templates.mirror.path + '/precreated/contrib/', name)
  end

  def delete_physically
    hardware_server.rpc_client.exec("rm /vz/template/cache/#{self.name}.tar.gz")
    destroy
  end
  
  private
  
  def self.get_available(dir)
    ftp = Net::FTP.new(AppConfig.os_templates.mirror.host)
    ftp.login
    ftp.chdir(dir)
    ftp.nlst().find_all { |file| file =~ /tar.gz$/  }
  end
  
  def self.download(hardware_server, path, name)
    hardware_server.rpc_client.job('wget', "-P /vz/template/cache/ ftp://" +
      AppConfig.os_templates.mirror.host + "/#{path}/#{name}.tar.gz")
  end
  
end
