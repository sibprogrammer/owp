class ServerTemplate < ActiveRecord::Base
  belongs_to :hardware_server
  attr_accessible :name, :start_on_boot, :nameserver, :search_domain, 
    :diskspace, :memory, :cpu_units, :cpus, :cpu_limit, :raw_limits
  attr_accessor :start_on_boot, :nameserver, :search_domain, :diskspace,
    :memory, :cpu_units, :cpus, :cpu_limit, :raw_limits
  validates_uniqueness_of :name, :scope => :hardware_server_id
  
  def delete_physically
    if hardware_server.default_server_template == name
      return false
    end
    
    hardware_server.rpc_client.exec("rm /etc/vz/conf/ve-#{self.name}.conf-sample")
    destroy
  end
  
  def get_advanced_limits
    load_config 
    
    limits = [
      'KMEMSIZE', 'LOCKEDPAGES', 'SHMPAGES', 'NUMPROC', 
      'PHYSPAGES', 'VMGUARPAGES', 'OOMGUARPAGES', 'NUMTCPSOCK', 'NUMFLOCK',
      'NUMPTY', 'NUMSIGINFO', 'TCPSNDBUF', 'TCPRCVBUF', 'OTHERSOCKBUF',
      'DGRAMRCVBUF', 'NUMOTHERSOCK', 'DCACHESIZE', 'NUMFILE',
      'AVNUMPROC', 'NUMIPTENT', 'DISKINODES'
    ]
    
    result = []
    
    limits.each { |limit|
      limit_values = @config.get(limit).split(":")
      result.push({ :name => limit, :soft_limit => limit_values[0], :hard_limit => limit_values[1] })
    }
    
    result
  end
  
  def save_physically
    return false if !valid?
    
    content = ""
    content << 'ONBOOT="' + (start_on_boot ? "yes" : "no") + '"' + "\n"
    content << "NAMESERVER=\"#{nameserver}\"\n" unless nameserver.blank?
    content << "SEARCHDOMAIN=\"#{search_domain}\"\n" unless search_domain.blank?
    content << "CPUUNITS=\"#{cpu_units}\"\n" unless cpu_units.blank?
    content << "CPUS=\"#{cpus}\"\n" unless cpus.blank?
    content << "CPULIMIT=\"#{cpu_limit}\"\n" unless cpu_limit.blank?
    
    privvmpages = memory.to_i * 1024 / 4
    content << "PRIVVMPAGES=\"#{privvmpages}:#{privvmpages}\"\n"
    disk = diskspace.to_i * 1024
    content << "DISKSPACE=\"#{disk}:#{disk}\"\n"
    
    # some hard-coded values
    content << "QUOTATIME=\"0\"\n"
    
    raw_limits.each { |limit|
      content << limit['name'] + "=\"" + limit['soft_limit'].to_s + ":" + limit['hard_limit'].to_s + "\"\n"
    }
    
    hardware_server.rpc_client.write_file("/etc/vz/conf/ve-#{self.name}.conf-sample", content)
    
    save
  end
  
  def get_nameserver
    load_config
    @config.get("NAMESERVER")
  end
  
  def get_search_domain
    load_config
    search_domain = @config.get("SEARCHDOMAIN")
  end
  
  def get_start_on_boot
    load_config
    @config.get("ONBOOT") == 'yes'
  end
  
  def get_diskspace
    load_config
    @config.get("DISKSPACE").split(":")[1].to_i / 1024
  end
  
  def get_memory
    load_config
    @config.get("PRIVVMPAGES").split(":")[1].to_i / 1024 * 4
  end
  
  def get_cpu_units
    load_config
    @config.get("CPUUNITS")
  end
  
  def get_cpus
    load_config
    @config.get("CPUS")
  end
  
  def get_cpu_limit
    load_config
    @config.get("CPULIMIT")
  end
  
  private
    
    def load_config
      if !@config then
        content = hardware_server.rpc_client.exec('cat', "/etc/vz/conf/ve-#{self.name}.conf-sample")['output'];
        @config = IniParser.new(content)
      end
        
      @config
    end
  
end
