class Backup < ActiveRecord::Base
  belongs_to :virtual_server
  
  def date
    match = name.match(/^ve-dump\.(\d+)\.(\d+)\.tar$/)
    Time.at(match[2].to_i)
  end
  
  def delete_physically
    hardware_server = virtual_server.hardware_server
    
    hardware_server.rpc_client.exec("rm #{hardware_server.backups_dir}/#{self.name}")
    destroy
  end
  
  def self.backup(virtual_server)
    veid = virtual_server.identity
    name = "ve-dump.#{veid}.#{Time.now.to_i}.tar"
    backup_name = "#{virtual_server.hardware_server.backups_dir}/#{name}"
    job = virtual_server.hardware_server.rpc_client.job('tar', "-cf #{backup_name} #{virtual_server.private_dir}")
    server_backup = Backup.new(:name => name, :virtual_server_id => virtual_server.id)
    { :job => job, :backup => server_backup }
  end
  
  def restore
    virtual_server.hardware_server.rpc_client.exec('rm', "-rf #{virtual_server.private_dir}") if virtual_server.private_dir.length > 1
    backup_name = "#{virtual_server.hardware_server.backups_dir}/#{name}"
    virtual_server.hardware_server.rpc_client.job('tar', "-xf #{backup_name} -C /")
  end
  
end
