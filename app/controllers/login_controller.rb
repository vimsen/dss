class LoginController < ApplicationController

  protect_from_forgery

  def index
  end

  def signin
    session[:user_id] = 1
    session[:user_displayName] = "Test User"
    session[:user_group] = 1
    redirect_to "/home"
        
  end  

  def signout
     session[:user_id]=nil
     session[:user_displayName]=nil
     flash[:notice] = t('login_page.signout_ok')
     redirect_to login_url         
  end 

end
