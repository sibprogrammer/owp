require 'net/ftp'

class OsTemplate < ActiveRecord::Base
  belongs_to :hardware_server
  
  def self.get_available_official
    get_available('/template/precreated/')
  end
  
  def self.get_available_contributed
    get_available('/template/precreated/contrib/')
  end
  
  def self.install_official(hardware_server, name)
    self.download(hardware_server, '/template/precreated/', name)
  end
  
  def self.install_contributed(hardware_server, name)
    self.download(hardware_server, '/template/precreated/contrib/', name)
  end
  
  private
  
  def self.get_available(dir)
    ftp = Net::FTP.new('download.openvz.org')
    ftp.login
    ftp.chdir(dir)
    ftp.nlst().find_all { |file| file =~ /tar.gz$/  }
  end
  
  def self.download(hardware_server, path, name)
    hardware_server.rpc_client.job('wget', "-P /vz/template/cache/ ftp://download.openvz.org/#{path}/#{name}.tar.gz")
  end
  
end
