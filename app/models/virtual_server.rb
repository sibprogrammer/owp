class VirtualServer < ActiveRecord::Base
  attr_accessible :identity, :ip_address, :host_name, :hardware_server_id,
    :orig_os_template, :password, :start_on_boot, :start_after_creation, :state,
    :nameserver, :search_domain, :diskspace, :memory, :password_confirmation,
    :user_id, :orig_server_template, :description, :cpu_units, :cpus, :cpu_limit,
    :expiration_date, :vswap, :daily_backup
  attr_accessor :password, :password_confirmation, :start_after_creation
  belongs_to :hardware_server
  belongs_to :user
  has_many :backups, :dependent => :destroy
  has_many :bean_counters, :dependent => :destroy

  validates_format_of :ip_address, :with => /^(((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(\/\d+)?|\s|(([\da-fA-F]{1,4}:?)|(::)){1,8})*|auto)$/
  validates_uniqueness_of :ip_address, :allow_blank => true
  validates_uniqueness_of :identity, :scope => :hardware_server_id
  validates_confirmation_of :password
  validates_format_of :nameserver, :with => /^((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})|\s|(([\da-fA-F]{1,4}:?)|(::)){1,8})*$/
  validates_format_of :search_domain, :with => /^([a-z0-9\-\.]+\s*)*$/i
  validates_format_of :host_name, :with => /^[a-z0-9\-\.]*$/i
  validates_format_of :description, :with => /^[a-z0-9\-\.\s]*$/i if AppConfig.vzctl.save_descriptions

  named_scope :daily_backed_up, :conditions => { :daily_backup => true }

  def self.ip_addresses
    result = []
    VirtualServer.all.each do |virtual_server|
      virtual_server.ip_address.to_s.split.each do |ip_address|
        result << {
          :name => ip_address,
          :virtual_server => virtual_server.screen_name,
          :virtual_server_id => virtual_server.id,
          :hardware_server => virtual_server.hardware_server.host,
          :hardware_server_id => virtual_server.hardware_server.id,
        }
      end
    end
    result
  end

  def expiration_date=(date)
    write_attribute(:expiration_date, date.gsub('.', '-'))
  end

  def get_limits
    parser = IniParser.new(hardware_server.rpc_client.exec('cat', "/etc/vz/conf/#{identity.to_s}.conf")['output'])

    limits = [
      'KMEMSIZE', 'LOCKEDPAGES', 'SHMPAGES', 'NUMPROC',
      'VMGUARPAGES', 'OOMGUARPAGES', 'NUMTCPSOCK', 'NUMFLOCK',
      'NUMPTY', 'NUMSIGINFO', 'TCPSNDBUF', 'TCPRCVBUF', 'OTHERSOCKBUF',
      'DGRAMRCVBUF', 'NUMOTHERSOCK', 'DCACHESIZE', 'NUMFILE',
      'AVNUMPROC', 'NUMIPTENT', 'DISKINODES'
    ]

    result = []

    limits.each do |limit|
      raw_limit = parser.get(limit)
      raw_limit = 'unlimited' if raw_limit.blank?
      raw_limit = "#{raw_limit}:#{raw_limit}" if !raw_limit.include?(':')
      limit_values = raw_limit.split(":")
      limit_values[0] = '' if 'unlimited' == limit_values[0]
      limit_values[1] = '' if 'unlimited' == limit_values[1]
      result.push({ :name => limit, :soft_limit => limit_values[0], :hard_limit => limit_values[1] })
    end

    result
  end

  def start
    return true if 'running' == real_state
    change_state('start', 'running')
  end

  def stop
    return true if 'stopped' == real_state
    change_state('stop', 'stopped')
  end

  def restart
    change_state('restart', 'running')
  end

  def delete_physically
    stop
    hardware_server.rpc_client.exec("mkdir -p #{shellescape(root_dir)}")
    hardware_server.rpc_client.exec('vzctl', 'destroy ' + identity.to_s)
    backups.each { |backup| backup.delete_physically }
    destroy
    EventLog.info("virtual_server.removed", { :identity => identity })
  end

  def save_limits(limits)
    orig_limits = get_limits
    vzctl_params = ''
    limits.each do |limit|
      orig_limit = orig_limits.find { |item| item[:name] == limit['name'] }
      if orig_limit[:soft_limit] != limit['soft_limit'] || orig_limit[:hard_limit] != limit['hard_limit']
        limit['soft_limit'] = 'unlimited' if '' == limit['soft_limit']
        limit['hard_limit'] = 'unlimited' if '' == limit['hard_limit']
        vzctl_params << "--" + limit['name'].downcase + " " + limit['soft_limit'].to_s + ":" + limit['hard_limit'].to_s + " "
      end
    end

    vzctl_set("#{vzctl_params} --save")
  end

  def save_physically
    return false if !valid?
    is_new = new_record?

    if is_new
      if identity.blank?
        hash = connection.select_one("SELECT MAX(identity) AS max_identity FROM virtual_servers WHERE hardware_server_id=#{hardware_server.id}")
        self.identity = hash['max_identity'].to_i + 1
      end
      hardware_server.rpc_client.exec('vzctl', "create #{identity.to_s} --ostemplate #{orig_os_template} --config #{orig_server_template}")
      self.state = 'stopped'

      if 'auto' == ip_address
        first_free_ip = hardware_server.free_ips.first
        self.ip_address = first_free_ip ? first_free_ip : ''
      end
    end

    if orig_server_template_changed?
      vzctl_set("--applyconfig #{orig_server_template} --save")
    end

    begin
      vzctl_set("--hostname #{shellescape(host_name)} --save") if !host_name.blank? and host_name_changed?
      vzctl_set("--userpasswd root:#{shellescape(password)}") if password and !password.blank?
      vzctl_set("--onboot " + (start_on_boot ? "yes" : "no") + " --save") if start_on_boot_changed?
      vzctl_set(nameserver.split.map { |ip| "--nameserver #{shellescape(ip)} " }.join + "--save") if !nameserver.blank? and nameserver_changed?
      vzctl_set("--searchdomain #{shellescape(search_domain)} --save") if !search_domain.blank? and search_domain_changed?
      vzctl_set("--cpuunits #{shellescape(cpu_units.to_s)} --save") if !cpu_units.blank? and cpu_units_changed?
      vzctl_set("--cpus #{shellescape(cpus.to_s)} --save") if !cpus.blank? and cpus_changed?
      vzctl_set("--cpulimit #{shellescape(cpu_limit.to_s)} --save") if !cpu_limit.blank? and cpu_limit_changed?
      vzctl_set("--description #{shellescape(description)} --save") if hardware_server.ve_descriptions_supported? and !description.empty? and description_changed?

      vzctl_set("--ipdel all --save") if !ip_address_was.blank? and ip_address_changed?
      vzctl_set(ip_address.split.map { |ip| "--ipadd #{ip} " }.join + "--save") if !ip_address.blank? and ip_address_changed?

      if memory_changed?
        if vswap and vswap > 0 and hardware_server.vswap
          vzctl_set("--ram #{shellescape(memory.to_s)}M --save")
        else
          privvmpages = 0 == memory.to_i ? 'unlimited' : memory.to_i * 1024 / 4
          vzctl_set("--privvmpages #{shellescape(privvmpages.to_s)} --save")
          vzctl_set("--physpages unlimited --save")
        end
      end

      if vswap_changed? and vswap and vswap > 0 and hardware_server.vswap
        vzctl_set("--swap #{shellescape(vswap.to_s)}M --save")
      end

      disk = 0 == diskspace.to_i ? 'unlimited' : diskspace.to_i * 1024
      vzctl_set("--diskspace #{shellescape(disk.to_s)} --save") if diskspace_changed?
    rescue HwDaemonExecException => exception
      delete_physically if is_new
      raise exception
    end

    self.host_name = host_name_was if !is_new and host_name.blank?
    self.nameserver = nameserver_was if !is_new and nameserver.blank?
    self.search_domain = search_domain_was if !is_new and search_domain.blank?

    start if start_after_creation and is_new

    result = save
    EventLog.info("virtual_server." + (is_new ? "created" : "updated"), { :identity => identity })
    result
  end

  def reinstall
    was_running = 'running' == real_state
    path = '/etc/vz/conf'
    tmp_template = "tmp.template"

    new_os_template = ""
    if orig_os_template_changed?
      new_os_template = " --ostemplate #{shellescape(orig_os_template)} "
      save
    end

    hardware_server.rpc_client.exec("cp #{path}/#{self.identity}.conf #{path}/ve-#{tmp_template}.conf-sample")
    stop
    hardware_server.rpc_client.exec('vzctl', "destroy #{shellescape(identity.to_s)}")
    hardware_server.rpc_client.exec('vzctl', "create #{shellescape(identity.to_s)} #{new_os_template} --config #{shellescape(tmp_template)}")
    change_state('start', 'running') if was_running
    hardware_server.rpc_client.exec("rm #{path}/ve-#{shellescape(tmp_template)}.conf-sample")

    true
  end

  def run_command(command)
    filename = "/tmp/vecmd_" + generate_id.to_s
    content = "#!/bin/sh\n#{command}"
    hardware_server.rpc_client.write_file(filename, content)

    begin
      result = hardware_server.rpc_client.exec('vzctl', "runscript #{shellescape(identity.to_s)} #{shellescape(filename)}")
    rescue HwDaemonExecException => e
      result = { 'error' => e }
    end

    hardware_server.rpc_client.exec("rm #{shellescape(filename)}")
    result
  end

  def cpu_load_average
    run_command('cat /proc/loadavg')['output'].split[0..2]
  end

  def disk_usage
    raw_info = run_command('stat -c "%s %b %a" -f /')['output'].split
    info = {}
    info['block_size'] = raw_info[0].to_i
    info['total_bytes'] = info['block_size'] * raw_info[1].to_i
    info['free_bytes'] = info['block_size'] * raw_info[2].to_i
    info['used_bytes'] = info['total_bytes'] - info['free_bytes']
    info['usage_percent'] = (info['used_bytes'].to_f / info['total_bytes'].to_f * 100).to_i
    info
  end

  def memory_usage
    raw_info = run_command('free  -bo')['output'].split("\n")[1].split
    info = {}
    info['total_bytes'] = raw_info[1].to_i
    info['used_bytes'] = raw_info[2].to_i
    info['free_bytes'] = raw_info[3].to_i
    info['usage_percent'] = (info['used_bytes'].to_f / info['total_bytes'].to_f * 100).to_i
    info
  end

  def backup
    Backup.backup(self)
  end

  def private_dir
    hardware_server.ve_private.sub('$VEID', identity.to_s)
  end

  def root_dir
    hardware_server.ve_root.sub('$VEID', identity.to_s)
  end

  def human_diskspace
    0 != self.diskspace ? self.diskspace : I18n.translate('admin.virtual_servers.limits.unlimited')
  end

  def human_memory
    0 != self.memory ? self.memory : I18n.translate('admin.virtual_servers.limits.unlimited')
  end

  def suspend
    hardware_server.rpc_client.exec('vzctl', "chkpnt #{identity.to_s} --suspend")
  end

  def resume
    hardware_server.rpc_client.exec('vzctl', "chkpnt #{identity.to_s} --resume")
  end

  def clone_physically(orig_server)
    return false if !valid?

    path = '/etc/vz/conf'
    hardware_server.rpc_client.exec("cp #{shellescape(path)}/#{shellescape(orig_server.identity.to_s)}.conf #{shellescape(path)}/#{shellescape(identity.to_s)}.conf")

    hardware_server.rpc_client.exec("mkdir -p #{shellescape(root_dir)}")

    orig_server.suspend
    hardware_server.rpc_client.exec("cp -a #{shellescape(orig_server.private_dir)} #{shellescape(self.private_dir)}")
    orig_server.resume

    begin
      vzctl_set("--userpasswd root:#{shellescape(password)}") if password and !password.blank?
      vzctl_set("--hostname #{shellescape(host_name)} --save") if !host_name.blank? and host_name_changed?
      vzctl_set("--ipdel all --save") if !ip_address_was.blank?
      vzctl_set(ip_address.split.map { |ip| "--ipadd #{shellescape(ip)} " }.join + "--save") if !ip_address.blank? and ip_address_changed?
    rescue HwDaemonExecException => exception
      raise exception
    end

    self.state = 'stopped'
    return false if !save

    start if 'running' == orig_server.state

    EventLog.info("virtual_server.cloned", { :identity => orig_server.identity })
    true
  end

  def migrate(target_hardware_server)
    hardware_server.rpc_client.exec('vzmigrate', "#{shellescape(target_hardware_server.host)} #{shellescape(identity.to_s)}")
    target_hardware_server.sync_virtual_servers
    destroy
  end

  def real_state
    counter = Watchdog.get_ve_counter('state', id)
    if counter
      current_state = counter.state
      if state != current_state
        self.state = current_state
        save
      end
    end

    state
  end

  def screen_name
    host_name.blank? ? "#" + identity.to_s : host_name
  end

  def validate
    return if 0 == IpPool.count or ip_address.blank? or !ip_address_changed?
    return if 'auto' == ip_address

    old_ips = ip_address_was.blank? ? [] : ip_address_was.split(' ')

    ip_address.split(' ').each do |ip|
      begin
        ip, netmask = ip.split('/')
        ip = IPAddr.new(ip).to_s
      rescue
        msg = I18n.t('activerecord.errors.models.virtual_server.attributes.ip_address.invalid')
        errors.add(:ip_address, msg)
        return
      end

      if !old_ips.include?(ip) and !hardware_server.free_ips.include?(ip)
        msg = I18n.t('activerecord.errors.models.virtual_server.attributes.ip_address.not_found_in_pool')
        errors.add(:ip_address, msg)
        return
      end
    end
  end

  def create_template(template_name)
    template_name = orig_os_template + '-' + template_name + '.tar.gz'
    templates_path = "#{hardware_server.templates_dir}/cache"
    template_exclude_list = File.read("#{Rails.root}/config/template_exclude.list")
    is_running = 'running' == real_state
    hardware_server.rpc_client.write_file("/tmp/owp-template-exclude.list", template_exclude_list)

    suspend if is_running

    begin
      hardware_server.rpc_client.exec("tar --numeric-owner -czf #{shellescape(templates_path)}/#{shellescape(template_name)} -X /tmp/owp-template-exclude.list -C #{shellescape(private_dir)} .")
    rescue => e
      resume if is_running
      raise e
    end

    resume if is_running

    hardware_server.rpc_client.exec("rm /tmp/owp-template-exclude.list")
    hardware_server.sync_os_templates
  end

  def create_daily_backup
    last_backup = backups.find_by_description('auto')
    last_backup.delete_physically if last_backup

    orig_ve_state = state
    suspend if 'running' == orig_ve_state

    backup_info = Backup.backup(self, false)
    backup_info.description = 'auto'
    backup_info.sync_size
    backup_info.save

    resume if 'running' == orig_ve_state
  end

  private

    def vzctl_set(param)
      hardware_server.rpc_client.exec('vzctl', "set #{shellescape(identity.to_s)} #{param}")
    end

    def change_state(state, status)
      begin
        hardware_server.rpc_client.exec('vzctl', shellescape(state) + ' ' + shellescape(identity.to_s))
      rescue HwDaemonExecException => e
        EventLog.error("virtual_server.change_state_failed", {
          :identity => identity, :state => state, :code => e.code.to_s
        })
        return false
      end

      Watchdog.remove_ve_counter('state', id)

      self.state = status
      save
    end

    def generate_id
      symbols = [('0'..'9'),('a'..'f')].map{ |i| i.to_a }.flatten
      (1..32).map{ symbols[rand(symbols.length)] }.join
    end

    # compatibility with old Ruby versions
    def shellescape(str)
      # An empty argument will be skipped, so return empty quotes.
      return "''" if str.empty?

      str = str.dup

      # Process as a single byte sequence because not all shell
      # implementations are multibyte aware.
      str.gsub!(/([^A-Za-z0-9_\-.,:\/@\n])/n, "\\\\\\1")

      # A LF cannot be escaped with a backslash because a backslash + LF
      # combo is regarded as line continuation and simply ignored.
      str.gsub!(/\n/, "'\n'")

      return str
    end

end
