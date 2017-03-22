require 'test_helper'

class LoginControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "should get index" do
    sign_in User.first
    get :index
    assert_response :success
  end

end
