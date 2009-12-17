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
    
    if result
      add_os_templates(rpc_client)
      add_virtual_servers(rpc_client)
    end
    
    result
  end
  
  def disconnect
    destroy
  end
  
  def rpc_client
    HwDaemonClient.new(self.host, self.auth_key)
  end
  
  def exec_command(command, args = '')
    rpc_client.exec(command, args)
  end
    
  def sync_os_templates
    rpc_client.exec('ls', '/vz/template/cache')['output'].split.each { |template_name|
      template_name.sub!(/\.tar.\gz/, '')
      if !OsTemplate.find_by_name(template_name)
        os_template = OsTemplate.new(:name => template_name)
        os_template.hardware_server = self
        os_template.save
      end
    }
  end
  
  private
  
  def add_os_templates(rpc_client)
    rpc_client.exec('ls', '/vz/template/cache')['output'].split.each { |template_name|
      os_template = OsTemplate.new(:name => template_name.sub(/\.tar.\gz/, ''))
      os_template.hardware_server = self
      os_template.save
    }
  end
  
  def add_virtual_servers(rpc_client)
    rpc_client.exec('vzlist', '-a -H -o veid,hostname,ip,status')['output'].split("\n").each { |vzlist_entry|
      ve_id, host_name, ip_address, ve_state = vzlist_entry.split
      virtual_server = VirtualServer.new(
        :identity => ve_id,
        :host_name => host_name,
        :ip_address => ip_address,
        :state => ve_state
      )
      
      parser = IniParser.new(rpc_client.exec('cat', "/etc/vz/conf/#{ve_id}.conf")['output'])
      os_template = OsTemplate.find_by_name(parser.get('OSTEMPLATE'))      
      virtual_server.os_template = os_template
      
      virtual_server.hardware_server = self
      
      virtual_server.save
    }
  end
  
end
