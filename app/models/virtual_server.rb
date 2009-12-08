class VirtualServer < ActiveRecord::Base
  attr_accessible :identity, :ip_address, :host_name, :hardware_server_id, :os_template_id, :password, :start_on_boot, :start_after_creation
  attr_accessor :password, :start_on_boot, :start_after_creation
  belongs_to :hardware_server
  belongs_to :os_template
  
  def start
    self.hardware_server.exec_command('vzctl', 'start ' + self.identity.to_s)
    self.state = 'running'
    save
  end
  
  def stop
    self.hardware_server.exec_command('vzctl', 'stop ' + self.identity.to_s)
    self.state = 'stopped'
    save
  end
  
  def restart
    self.hardware_server.exec_command('vzctl', 'restart ' + self.identity.to_s)
    self.state = 'running'
    save
  end
    
  def delete_physically
    stop
    self.hardware_server.exec_command('vzctl', 'destroy ' + self.identity.to_s)
    destroy
  end
     
  def create_physically    
    self.hardware_server.exec_command('vzctl', "create #{self.identity.to_s}" +
      " --ostemplate #{self.os_template.name}" +
      " --ipadd #{self.ip_address}" +
      " --hostname #{self.host_name}"
    )
    self.state = 'stopped'
    result = save
    tune_server_settings
    result
  end
  
  private
  
  def tune_server_settings    
    self.hardware_server.exec_command('vzctl', "set #{self.identity.to_s} --userpasswd root:#{password}") if password
    self.hardware_server.exec_command('vzctl', "set #{self.identity.to_s} --onboot yes --save") if start_on_boot
    self.start if start_after_creation
  end
  
end
