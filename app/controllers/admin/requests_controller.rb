class Admin::RequestsController < Admin::Base
  before_filter :is_allowed

  def list
    @up_level = '/admin/dashboard'
    @requests_list = requests_list
  end

  def list_data
    render :json => { :data => requests_list }
  end

  def delete
    redirect_to :controller => 'admin/dashboard' if !@current_user.can_handle_requests?
    objects_group_operation(Request, :destroy)
  end

  def show
    @request = Request.find_by_id(params[:id])
    redirect_to :controller => 'dashboard' and return if !@request or (!@current_user.can_handle_requests? and (@request.user.id != @current_user.id))
    @up_level = '/admin/requests/list'
    @comments = request_comments_list(@request)
  end

  def comments_list_data
    @request = Request.find_by_id(params[:id])
    redirect_to :controller => 'dashboard' and return if !@request or (!@current_user.can_handle_requests? and (@request.user.id != @current_user.id))
    render :json => { :data => request_comments_list(@request) }
  end

  def create
    request = Request.new
    request.attributes = params
    request.user = @current_user

    if request.save
      render :json => { :success => true }
    else
      render :json => { :success => false, :form_errors => request.errors }
    end
  end

  def add_comment
    @request = Request.find_by_id(params[:request_id])
    redirect_to :controller => 'dashboard' and return if !@request or (!@current_user.can_handle_requests? and (@request.user.id != @current_user.id))

    comment = Comment.new
    comment.attributes = params
    comment.user = @current_user
    comment.request = @request

    if comment.save
      render :json => { :success => true }
    else
      render :json => { :success => false, :form_errors => comment.errors }
    end
  end

  def toggle
    @request = Request.find_by_id(params[:request_id])
    redirect_to :controller => 'dashboard' and return if !@request or (!@current_user.can_handle_requests? and (@request.user.id != @current_user.id))

    @request.opened = @current_user.can_handle_requests? ? !@request.opened : true
    @request.save

    if @request.opened
      redirect_to :action => 'show', :id => @request.id
    else
      redirect_to :action => 'list'
    end
  end

  private

    def requests_list
      requests = @current_user.can_handle_requests? ? Request.all : @current_user.requests
      requests.map! do |request|
        {
          :id => request.id,
          :opened => request.opened,
          :subject => CGI.escapeHTML(request.subject),
          :replies => request.comments.count,
          :author => request.user ? request.user.login : '',
          :updated_at => local_datetime(request.updated_at),
        }
      end
    end

    def request_comments_list(request)
      comments = request.comments
      comments.map! do |comment|
        {
          :id => comment.id,
          :content => CGI.escapeHTML(comment.content).gsub(/\n/, '<br />'),
          :author => comment.user ? comment.user.login : '',
          :created_at => local_datetime(comment.created_at),
        }
      end

      comments.insert(0, {
        :id => 0,
        :content => CGI.escapeHTML(request.content).gsub(/\n/, '<br />'),
        :author => request.user ? request.user.login : '',
        :created_at => local_datetime(request.created_at),
      })
    end

    def is_allowed
      redirect_to :controller => 'admin/dashboard' if !@current_user.can_create_requests?
    end

end
