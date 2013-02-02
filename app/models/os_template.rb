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

  def self.install_from_url(hardware_server, url)
    hardware_server.rpc_client.job('wget', "-P #{hardware_server.templates_dir}/cache/ #{url}")
  end

  def delete_physically
    hardware_server.rpc_client.exec("rm #{hardware_server.templates_dir}/cache/#{self.name}.tar.gz")
    destroy
  end

  private

  def self.get_available(dir)
    ftp = Net::FTP.new(AppConfig.os_templates.mirror.host)
    ftp.login('anonymous', 'anonymous')
    ftp.passive = true if AppConfig.os_templates.passive_ftp
    ftp.chdir(dir)
    ftp.list('-a').map do |file|
      { 'name' => file.split.last, 'size' => file.split[4] } if file =~ /tar\.gz$/
    end.compact
  end

  def self.download(hardware_server, path, name)
    hardware_server.rpc_client.job('wget', "-P #{hardware_server.templates_dir}/cache/ ftp://" +
      AppConfig.os_templates.mirror.host + "/#{path}/#{name}.tar.gz")
  end

end
