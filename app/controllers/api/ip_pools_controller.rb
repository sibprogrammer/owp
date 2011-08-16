class Api::IpPoolsController < Api::Base
  before_filter :superadmin_required
  before_filter :set_ip_pool_by_id, :only => [ :get, :delete, :update ]

  def list
    ip_pools = IpPool.all
    render_object_result(ip_pools, :root => 'ip_pools')
  end

  def get
    render_object_result(@ip_pool)
  end

  def delete
    @ip_pool.destroy
    render_scalar_result(true)
  end

  def create
    create_or_update_ip_pool
  end

  def update
    create_or_update_ip_pool
  end

  private

    def set_ip_pool_by_id
      @ip_pool = IpPool.find_by_id(params[:id])
      render_error :reason => 'object_not_found' if !@ip_pool
    end

    def create_or_update_ip_pool
      @ip_pool = IpPool.new unless @ip_pool
      @ip_pool.attributes = params
      render_object_save_result(@ip_pool.save, @ip_pool)
    end

end
