include ActionView::Helpers::TextHelper

class Admin::HardwareServersController < Admin::Base
  before_filter :superadmin_required

  def list
    @up_level = '/admin/dashboard'
    @hardware_servers_list = hardware_servers_list
  end

  def list_data
    render :json => { :data => hardware_servers_list }
  end

  def save
    @hardware_server = (params[:id].to_i > 0) ? HardwareServer.find_by_id(params[:id]) : HardwareServer.new
    params.delete(:auth_key) if !@hardware_server.new_record? && params[:auth_key].blank?
    @hardware_server.attributes = params
    @hardware_server.use_ssl = params.key?(:use_ssl)

    if @hardware_server.connect(params[:root_password])
      render :json => { :success => true }
    else
      render :json => { :success => false, :form_errors => @hardware_server.errors }
    end
  end

  def disconnect
    objects_group_operation(HardwareServer, :disconnect)
  end

  def show
    @hardware_server = HardwareServer.find_by_id(params[:id])
    redirect_to :action => 'list' if !@hardware_server and return

    @up_level = '/admin/hardware-servers/list'
    @virtual_servers_list = get_virtual_servers_map(@hardware_server.virtual_servers)
    @hardware_server_stats = get_usage_stats(@hardware_server)
  end

  def sync
    objects_group_operation(HardwareServer, :sync)
  end

  def reboot
    objects_group_operation(HardwareServer, :reboot)
  end

  def load_data
    hardware_server = HardwareServer.find_by_id(params[:id])
    redirect_to :action => 'list' if !hardware_server and return
    render :json => { :success => true, :data => {
      :host => hardware_server.host,
      :description => hardware_server.description,
      :daemon_port => hardware_server.daemon_port,
      :use_ssl => hardware_server.use_ssl,
    }}
  end

  def get_stats
    hardware_server = HardwareServer.find_by_id(params[:id])
    redirect_to :action => 'list' if !hardware_server and return
    render :json => { :success => true, :data => get_usage_stats(hardware_server) }
  end

  def free_ips_list_data
    hardware_server = HardwareServer.find_by_id(params[:id])
    redirect_to :action => 'list' if !hardware_server and return
    list = hardware_server.free_ips.map { |item| { :address => item }}
    list = [{ :address => 'auto' }] + list if !list.blank? and 'add' == params[:mode]
    render :json => { :data => list }
  end

  private

    def hardware_servers_list
      hardware_servers = HardwareServer.all
      hardware_servers.map! do |item|
        {
          :id => item.id,
          :host => item.host,
          :virtual_servers => item.virtual_servers.count,
          :description => item.description
        }
      end
    end

    def get_usage_stats(hardware_server)
      stats = []

      os_version = hardware_server.os_version
      stats << {
        :parameter => t('admin.hardware_servers.stats.field.os_version'),
        :value => os_version.blank? ? '-' : os_version,
      }

      cpu_load_average = hardware_server.cpu_load_average
      stats << {
        :parameter => t('admin.hardware_servers.stats.field.cpu_load_average'),
        :value => cpu_load_average.blank? ? '-' : cpu_load_average.join(', '),
      }

      helper = Object.new.extend(ActionView::Helpers::NumberHelper)
      disk_usage = hardware_server.disk_usage

      if !disk_usage.blank?
        disk_usage.each do |partition|
          stats << {
            :parameter => t('admin.hardware_servers.stats.field.disk_usage', :partition => partition['mount_point']),
            :value => {
              'text' => t(
                'admin.hardware_servers.stats.value.disk_usage',
                :percent => partition['usage_percent'].to_s,
                :free =>  helper.number_to_human_size(partition['free_bytes'], :locale => :en),
                :used => helper.number_to_human_size(partition['used_bytes'], :locale => :en),
                :total => helper.number_to_human_size(partition['total_bytes'], :locale => :en)
              ),
              'percent' => partition['usage_percent'].to_f / 100
            }
          }
        end
      end

      memory_usage = hardware_server.memory_usage

      if !memory_usage.blank?
        stats << {
          :parameter => t('admin.hardware_servers.stats.field.memory_usage'),
          :value => {
            'text' => t(
              'admin.hardware_servers.stats.value.memory_usage',
              :percent => memory_usage['usage_percent'].to_s,
              :free =>  helper.number_to_human_size(memory_usage['free_bytes'], :locale => :en),
              :used => helper.number_to_human_size(memory_usage['used_bytes'], :locale => :en),
              :total => helper.number_to_human_size(memory_usage['total_bytes'], :locale => :en)
            ),
            'percent' => memory_usage['usage_percent'].to_f / 100
          }
        }
      end

      stats
    end

end
