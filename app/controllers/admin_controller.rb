class AdminController < ApplicationController
  layout 'admin'  
  before_filter :login_required
end
