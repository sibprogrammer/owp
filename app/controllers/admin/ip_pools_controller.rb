class Admin::IpPoolsController < Admin::Base
  before_filter :superadmin_required

  def list_data
    render :json => { :data => ip_pools_list }
  end

  def delete
    objects_group_operation(IpPool, :destroy)
  end

  def update
    ip_pool = (params[:id].to_i > 0) ? IpPool.find_by_id(params[:id]) : IpPool.new
    ip_pool.attributes = params

    if ip_pool.save
      render :json => { :success => true }
    else
      render :json => { :success => false, :form_errors => ip_pool.errors }
    end
  end

  def load_data
    ip_pool = IpPool.find_by_id(params[:id])
    redirect_to :controller => 'ip_addresses', :action => 'list' and return if !ip_pool

    render :json => { :success => true, :data => {
      :first_ip => ip_pool.first_ip,
      :last_ip => ip_pool.last_ip,
      :hardware_server_id => ip_pool.hardware_server_id.to_i,
    }}
  end

end
