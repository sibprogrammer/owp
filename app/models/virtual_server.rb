class VirtualServer < ActiveRecord::Base
  attr_accessible :identity, :ip_address, :host_name, :hardware_server_id, 
    :orig_os_template, :password, :start_on_boot, :start_after_creation, :state,
    :nameserver, :search_domain, :diskspace, :memory, :password_confirmation,
    :user_id, :orig_server_template
  attr_accessor :password, :password_confirmation, :start_after_creation
  belongs_to :hardware_server
  belongs_to :user
  
  validates_format_of :ip_address, :with => /^((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})|\s)*$/
  validates_uniqueness_of :ip_address
  validates_uniqueness_of :identity, :scope => :hardware_server_id
  validates_confirmation_of :password
  validates_format_of :nameserver, :with => /^((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})|\s)*$/

  def get_limits
    parser = IniParser.new(hardware_server.rpc_client.exec('cat', "/etc/vz/conf/#{identity.to_s}.conf")['output'])
    
    limits = [
      'KMEMSIZE', 'LOCKEDPAGES', 'PRIVVMPAGES', 'SHMPAGES', 'NUMPROC', 
      'PHYSPAGES', 'VMGUARPAGES', 'OOMGUARPAGES', 'NUMTCPSOCK', 'NUMFLOCK',
      'NUMPTY', 'NUMSIGINFO', 'TCPSNDBUF', 'TCPRCVBUF', 'OTHERSOCKBUF',
      'OTHERSOCKBUF', 'DGRAMRCVBUF', 'NUMOTHERSOCK', 'DCACHESIZE', 'NUMFILE',
      'AVNUMPROC', 'NUMIPTENT', 'DISKSPACE', 'DISKINODES'
    ]
    
    result = []
    
    limits.each { |limit|
      limit_values = parser.get(limit).split(":")
      result.push({ :name => limit, :soft_limit => limit_values[0].to_i, :hard_limit => limit_values[1].to_i })
    }
    
    result
  end

  def start
    hardware_server.rpc_client.exec('vzctl', 'start ' + identity.to_s)
    self.state = 'running'
    save
  end
  
  def stop
    hardware_server.rpc_client.exec('vzctl', 'stop ' + identity.to_s)
    self.state = 'stopped'
    save
  end
  
  def restart
    hardware_server.rpc_client.exec('vzctl', 'restart ' + identity.to_s)
    self.state = 'running'
    save
  end
    
  def delete_physically
    stop
    hardware_server.rpc_client.exec('vzctl', 'destroy ' + identity.to_s)
    destroy
    EventLog.info("virtual_server.removed", { :identity => identity })
  end
     
  def save_physically
    return false if !valid?
    
    if new_record?
      hardware_server.rpc_client.exec('vzctl', "create #{identity.to_s} --ostemplate #{orig_os_template} --config #{orig_server_template}")
      self.state = 'stopped'
    end
  
    if orig_server_template_changed?
      vzctl_set("--applyconfig #{orig_server_template} --save")
    end
    
    vzctl_set("--hostname #{host_name} --save") if !host_name.empty?
    vzctl_set("--ipdel all " + ip_address.split.map { |ip| "--ipadd #{ip} " }.join + "--save")
    vzctl_set("--userpasswd root:#{password}") if !password.empty?
    vzctl_set("--onboot " + (start_on_boot ? "yes" : "no") + " --save")
    vzctl_set(nameserver.split.map { |ip| "--nameserver #{ip} " }.join + "--save") if !nameserver.empty?
    vzctl_set("--searchdomain #{search_domain} --save") if !search_domain.empty?
    vzctl_set("--diskspace #{diskspace * 1024} --privvmpages #{memory * 1024 / 4} --save")
    start if start_after_creation
  
    result = save
    EventLog.info("virtual_server.created", { :identity => identity })
    result
  end
  
  private

    def vzctl_set(param)
      hardware_server.rpc_client.exec('vzctl', "set #{identity.to_s} #{param}")
    end
  
end
