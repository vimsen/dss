require 'test_helper'

class SlaControllerTest < ActionController::TestCase
  test "should get monitor" do
    get :monitor
    assert_response :success
  end

end
