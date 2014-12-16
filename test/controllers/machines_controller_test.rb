require 'test_helper'

class MachinesControllerTest < ActionController::TestCase
  test "should not get index (when not logged in)" do
    get :index
    assert_response :redirect
  end

  test "should get index" do
    User.first.add_role "admin"
    sign_in User.first
    get :index
    assert_response :success
  end
end
