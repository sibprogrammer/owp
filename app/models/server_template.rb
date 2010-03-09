class ServerTemplate < ActiveRecord::Base
  belongs_to :hardware_server
  
  def delete_physically
    if hardware_server.default_server_template == name
      return false
    end
    
    hardware_server.rpc_client.exec("rm /etc/vz/conf/ve-#{self.name}.conf-sample")
    destroy
  end
  
end
