class Admin::Base < ApplicationController
  layout 'admin'
  before_filter :login_required, :servers_list

  protected

    def superadmin_required
      redirect_to :controller => 'admin/dashboard' if !@current_user.superadmin?
    end

    def get_virtual_servers_map(virtual_servers)
      virtual_servers = virtual_servers.map do |virtual_server|
        {
          :id => virtual_server.id,
          :identity => virtual_server.identity,
          :ip_address => virtual_server.ip_address.blank? ? '' : virtual_server.ip_address.split.join(', '),
          :host_name => virtual_server.host_name,
          :state => virtual_server.real_state,
          :os_template_name => virtual_server.orig_os_template,
          :diskspace => virtual_server.human_diskspace,
          :memory => virtual_server.human_memory,
          :expiration_date => virtual_server.expiration_date.blank? ? '' : format_date(virtual_server.expiration_date),
          :is_expired => !virtual_server.expiration_date.blank? && Date.today > virtual_server.expiration_date,
          :owner => virtual_server.user ? virtual_server.user.login : '',
          :description => virtual_server.description.to_s,
        }
      end
    end

    def objects_group_operation(model, operation, &access)
      success = true

      params[:ids].split(',').each do |id|
        object = model.find(id)
        if block_given?
          next if !access.call(object)
        end
        success = false if !object || !object.send(operation)
      end

      render :json => { :success => success }
    end

    def ip_pools_list
      IpPool.all.collect do |ip_pool|
        {
          :id => ip_pool.id,
          :first_ip => ip_pool.first_ip,
          :last_ip => ip_pool.last_ip,
          :free_ips => ip_pool.free_ips,
          :used_ips => ip_pool.used_ips,
          :total_ips => ip_pool.total_ips,
          :server => ip_pool.hardware_server ? ip_pool.hardware_server.host : t('admin.ip_pools.form.create.field.all_servers'),
        }
      end
    end

end
