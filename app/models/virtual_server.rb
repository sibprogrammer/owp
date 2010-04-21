class VirtualServer < ActiveRecord::Base
  attr_accessible :identity, :ip_address, :host_name, :hardware_server_id, 
    :orig_os_template, :password, :start_on_boot, :start_after_creation, :state,
    :nameserver, :search_domain, :diskspace, :memory, :password_confirmation,
    :user_id, :orig_server_template, :description
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
      'KMEMSIZE', 'LOCKEDPAGES', 'SHMPAGES', 'NUMPROC', 
      'PHYSPAGES', 'VMGUARPAGES', 'OOMGUARPAGES', 'NUMTCPSOCK', 'NUMFLOCK',
      'NUMPTY', 'NUMSIGINFO', 'TCPSNDBUF', 'TCPRCVBUF', 'OTHERSOCKBUF',
      'OTHERSOCKBUF', 'DGRAMRCVBUF', 'NUMOTHERSOCK', 'DCACHESIZE', 'NUMFILE',
      'AVNUMPROC', 'NUMIPTENT', 'DISKINODES'
    ]
    
    result = []
    
    limits.each { |limit|
      limit_values = parser.get(limit).split(":")
      result.push({ :name => limit, :soft_limit => limit_values[0].to_i, :hard_limit => limit_values[1].to_i })
    }
    
    result
  end

  def start
    return true if 'running' == state
    change_state('start', 'running')
  end
  
  def stop
    return true if 'stopped' == state
    change_state('stop', 'stopped')
  end
  
  def restart
    change_state('restart', 'running')
  end
  
  def delete_physically
    stop
    hardware_server.rpc_client.exec('vzctl', 'destroy ' + identity.to_s)
    destroy
    EventLog.info("virtual_server.removed", { :identity => identity })
  end
  
  def save_limits(limits)
    vzctl_params = ''
    limits.each { |limit|
      vzctl_params << "--" + limit['name'].downcase + " " + limit['soft_limit'].to_s + ":" + limit['hard_limit'].to_s + " "
    }
    
    vzctl_set("#{vzctl_params} --save")
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
    
    begin
      vzctl_set("--hostname #{host_name} --save") if !host_name.empty?
      vzctl_set("--ipdel all " + ip_address.split.map { |ip| "--ipadd #{ip} " }.join + "--save")
      vzctl_set("--userpasswd root:#{password}") if !password.empty?
      vzctl_set("--onboot " + (start_on_boot ? "yes" : "no") + " --save")
      vzctl_set(nameserver.split.map { |ip| "--nameserver #{ip} " }.join + "--save") if !nameserver.empty?
      vzctl_set("--searchdomain #{search_domain} --save") if !search_domain.empty?
      vzctl_set("--diskspace #{diskspace * 1024} --privvmpages #{memory * 1024 / 4} --save")
    rescue HwDaemonExecException => exception
      delete_physically
      raise exception
    end
    
    start if start_after_creation
  
    result = save
    EventLog.info("virtual_server.created", { :identity => identity })
    result
  end
  
  def reinstall
    was_running = 'running' == state
    path = '/etc/vz/conf'
    tmp_template = "tmp.template"
    
    hardware_server.rpc_client.exec("cp #{path}/#{self.identity}.conf #{path}/ve-#{tmp_template}.conf-sample")
    stop
    hardware_server.rpc_client.exec('vzctl', 'destroy ' + identity.to_s)
    hardware_server.rpc_client.exec('vzctl', "create #{identity.to_s} --config #{tmp_template}")
    change_state('start', 'running') if was_running
    hardware_server.rpc_client.exec("rm #{path}/ve-#{tmp_template}.conf-sample")
    
    EventLog.info("virtual_server.reinstall", { :identity => identity })
    true
  end
  
  private

    def vzctl_set(param)
      hardware_server.rpc_client.exec('vzctl', "set #{identity.to_s} #{param}")
    end
    
    def change_state(state, status)
      begin
        hardware_server.rpc_client.exec('vzctl', state + ' ' + identity.to_s)
      rescue HwDaemonExecException => e
        EventLog.error("virtual_server.change_state_failed", {
          :identity => identity, :state => state, :code => e.code.to_s
        })
        return false
      end
      
      self.state = status
      save
    end
  
end
