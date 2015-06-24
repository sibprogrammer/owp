class Backup < ActiveRecord::Base
  belongs_to :virtual_server

  def date
    match = name.match(/^ve-dump\.(\d+)\.(\d+)\.tar$/)
    Time.at(match[2].to_i)
  end

  def delete_physically
    hardware_server = virtual_server.hardware_server

    hardware_server.rpc_client.exec("rm -f #{hardware_server.backups_dir}/#{self.name}")
    destroy
  end

  def self.create_backup(virtual_server, ve_state, description)
    orig_ve_state = virtual_server.state
    if 'running' == orig_ve_state
      case ve_state
        when 'suspend' then virtual_server.suspend
        when 'stop' then virtual_server.stop
      end
    end

    hardware_server = virtual_server.hardware_server
    result = virtual_server.backup
    job_id = result[:job]['job_id']
    backup = result[:backup]
    backup.description = description

    virtual_server.spawn do
      job = BackgroundJob.create('backups.create', { :identity => virtual_server.identity, :host => hardware_server.host })

      while true
        job_running = false
        job_running = true if hardware_server.rpc_client.job_status(job_id)['alive']
        break unless job_running
        sleep 10
      end

      job.finish
      backup.sync_size
      backup.save

      if 'running' == orig_ve_state
        case ve_state
          when 'suspend' then virtual_server.resume
          when 'stop' then virtual_server.start
        end
      end
    end

  end

  def self.backup_job(virtual_server, async = true)
    veid = virtual_server.identity
    name = "ve-dump.#{veid}.#{Time.now.to_i}.tar"
    backup_name = "#{virtual_server.hardware_server.backups_dir}/#{name}"
    server_backup = Backup.new(:name => name, :virtual_server_id => virtual_server.id)

    if async
      job = virtual_server.hardware_server.rpc_client.job('tar', "-cf #{backup_name} #{virtual_server.private_dir}")
      { :job => job, :backup => server_backup }
    else
      virtual_server.hardware_server.rpc_client.exec('tar', "-cf #{backup_name} #{virtual_server.private_dir}")
      server_backup
    end
  end

  def restore
    orig_ve_state = virtual_server.state
    virtual_server.stop if 'running' == orig_ve_state

    job_id = restore_now['job_id']

    spawn do
      job = BackgroundJob.create('backups.restore_job', { :identity => virtual_server.identity, :host => virtual_server.hardware_server.host })

      while true
        job_running = false
        job_running = true if virtual_server.hardware_server.rpc_client.job_status(job_id)['alive']
        break unless job_running
        sleep 10
      end

      job.finish
      virtual_server.start if 'running' == orig_ve_state
    end

  end

  def restore_job
    virtual_server.hardware_server.rpc_client.exec('rm', "-rf #{virtual_server.private_dir}") if virtual_server.private_dir.length > 1
    backup_name = "#{virtual_server.hardware_server.backups_dir}/#{name}"
    virtual_server.hardware_server.rpc_client.job('tar', "-xf #{backup_name} -C /")
  end

  def sync_size
    backup_file = virtual_server.hardware_server.backups_dir + '/' + name
    file_info = virtual_server.hardware_server.rpc_client.exec('ls', "--block-size=M -s #{backup_file}")['output']
    size, filename = file_info.split
    self.size = size.to_i
  end

end
