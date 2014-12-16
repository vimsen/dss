require 'test_helper'

class IntellenMockControllerTest < ActionController::TestCase
  test "should get getdata" do
    User.first.add_role "admin"
    sign_in User.first
    get :getdata
    assert_response :success
  end

end
