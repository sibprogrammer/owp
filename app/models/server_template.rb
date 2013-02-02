class ServerTemplate < ActiveRecord::Base
  include ApplicationHelper

  belongs_to :hardware_server
  attr_accessible :name, :start_on_boot, :nameserver, :search_domain,
    :diskspace, :memory, :cpu_units, :cpus, :cpu_limit, :raw_limits, :vswap
  attr_accessor :start_on_boot, :nameserver, :search_domain, :diskspace,
    :memory, :cpu_units, :cpus, :cpu_limit, :raw_limits, :vswap
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
      'VMGUARPAGES', 'OOMGUARPAGES', 'NUMTCPSOCK', 'NUMFLOCK',
      'NUMPTY', 'NUMSIGINFO', 'TCPSNDBUF', 'TCPRCVBUF', 'OTHERSOCKBUF',
      'DGRAMRCVBUF', 'NUMOTHERSOCK', 'DCACHESIZE', 'NUMFILE',
      'AVNUMPROC', 'NUMIPTENT', 'DISKINODES'
    ]

    result = []

    limits.each do |limit|
      limit_values = get_parsed_limit(@config.get(limit))
      result.push({ :name => limit, :soft_limit => limit_values[0], :hard_limit => limit_values[1] })
    end

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

    if vswap.to_i > 0 and hardware_server.vswap
      content << "PHYSPAGES=\"0:#{memory}M\"\n"
      content << "SWAPPAGES=\"0:#{vswap}M\"\n"
    else
      privvmpages = 0 == memory.to_i ? 'unlimited' : memory.to_i * 1024 / 4
      content << "PRIVVMPAGES=\"#{privvmpages}:#{privvmpages}\"\n"
      content << "PHYSPAGES=\"unlimited\"\n"
    end

    disk = 0 == diskspace.to_i ? 'unlimited' : diskspace.to_i * 1024
    content << "DISKSPACE=\"#{disk}:#{disk}\"\n"

    # some hard-coded values
    content << "QUOTATIME=\"0\"\n"

    raw_limits.each do |limit|
      limit['soft_limit'] = 'unlimited' if '' == limit['soft_limit']
      limit['hard_limit'] = 'unlimited' if '' == limit['hard_limit']
      if limit['soft_limit'] == limit['hard_limit']
        content << limit['name'] + "=\"" + limit['hard_limit'].to_s + "\"\n"
      else
        content << limit['name'] + "=\"" + limit['soft_limit'].to_s + ":" + limit['hard_limit'].to_s + "\"\n"
      end
    end

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
    diskspace_limit = get_diskspace_mb(@config.get("DISKSPACE"))
    0 == diskspace_limit ? '' : diskspace_limit
  end

  def get_memory
    load_config

    if vswap_enabled?
      get_ram_mb(@config.get('PHYSPAGES'))
    else
      memory_limit = get_parsed_limit(@config.get("PRIVVMPAGES"))
      0 == memory_limit.last.to_i ? '' : (memory_limit.last.to_i / 1024 * 4)
    end
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

  def vswap_enabled?
    load_config
    nil != @config.get("SWAPPAGES")
  end

  def get_vswap
    load_config
    vswap_limit = get_ram_mb(@config.get("SWAPPAGES"))
    0 == vswap_limit ? '' : vswap_limit
  end

  private

    def load_config
      if !@config then
        content = hardware_server.rpc_client.exec('cat', "/etc/vz/conf/ve-#{self.name}.conf-sample")['output'];
        @config = IniParser.new(content)
      end

      @config
    end

    def get_parsed_limit(limit)
      limit = 'unlimited' if limit.blank?
      limit = "#{limit}:#{limit}" if !limit.include?(':')
      limit_values = limit.split(":")
      limit_values[0] = '' if 'unlimited' == limit_values[0]
      limit_values[1] = '' if 'unlimited' == limit_values[1]
      limit_values
    end

end
