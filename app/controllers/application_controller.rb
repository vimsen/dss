class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.


#  protect_from_forgery with: :exception
  protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.format == 'application/json' }

  acts_as_token_authentication_handler_for User
  before_action :authenticate_user!, :except => [:getdata, :prosumer, :getdayahead]

  check_authorization :unless => :do_not_check_authorization?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to request.referer || root_path, :alert => exception.message
  end

  def after_sign_in_path_for(resource)
    sign_in_url = url_for(:action => 'new', :controller => 'sessions', :only_path => false, :protocol => 'http')
    if request.referer == sign_in_url
    super
    else
      stored_location_for(resource) || request.referer || root_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  def do_not_check_authorization?
    respond_to?(:devise_controller?) # or
  # condition_one? or
  # condition_two?
  end
end
