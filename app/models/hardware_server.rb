class HardwareServer < ActiveRecord::Base
  attr_accessible :host, :auth_key, :description  
  validates_uniqueness_of :host
  has_many :os_templates, :dependent => :destroy
  has_many :virtual_servers, :dependent => :destroy
  
  def connect    
    begin
      if !rpc_client.ping
        self.errors.add :auth_key, :bad_auth
        return false
      end
    rescue SocketError => socket_error
      self.errors.add :host, :connection
      return false
    end
    
    result = save    
    sync if result
    EventLog.info("hardware_server.connect", { :host => self.host })
    result
  end
  
  def disconnect
    destroy
    EventLog.info("hardware_server.disconnect", { :host => self.host })
  end
  
  def rpc_client
    HwDaemonClient.new(self.host, self.auth_key)
  end
      
  def sync_os_templates
    os_templates_on_server = rpc_client.exec('ls', '/vz/template/cache')['output'].split
    
    os_templates.each { |template|
      if !os_templates_on_server.include?(template.name + '.tar.gz')
        template.destroy
      end
    }
    
    os_templates_on_server.each { |template_name|
      template_name.sub!(/\.tar.\gz/, '')
      if !OsTemplate.find_by_name_and_hardware_server_id(template_name, self.id)
        os_template = OsTemplate.new(:name => template_name)
        os_template.hardware_server = self
        os_template.save
      end
    }
  end
  
  def sync_virtual_servers
    ves_on_server = rpc_client.exec('vzlist', '-a -H -o veid,hostname,ip,status')['output'].split("\n")
    
    ves_ids_on_server = ves_on_server.map { |vzlist_entry|
      vzlist_entry = vzlist_entry.split.first
    }
    
    virtual_servers.each { |virtual_server|
      if !ves_ids_on_server.include?(virtual_server.identity)
        virtual_server.destroy
      end
    }
    
    ves_on_server.each { |vzlist_entry|
      ve_id, host_name, ip_address, ve_state = vzlist_entry.split
      
      virtual_server = virtual_servers.find_by_identity(ve_id)
      virtual_server = VirtualServer.new(:identity => ve_id) unless virtual_server
      
      virtual_server.host_name = host_name
      virtual_server.ip_address = ip_address
      virtual_server.state = ve_state
        
      parser = IniParser.new(rpc_client.exec('cat', "/etc/vz/conf/#{ve_id}.conf")['output'])
      os_template = os_templates.find_by_name(parser.get('OSTEMPLATE'))      
      virtual_server.os_template = os_template        
      virtual_server.hardware_server = self        
      virtual_server.save
    }
  end
  
  def sync
    sync_os_templates
    sync_virtual_servers
    EventLog.info("hardware_server.sync", { :host => self.host })
  end
    
end
