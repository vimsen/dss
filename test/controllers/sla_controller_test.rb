require 'test_helper'

class SlaControllerTest < ActionController::TestCase
  test "should get monitor" do
    sign_in User.first
    get :monitor
    assert_response :success
  end

end
