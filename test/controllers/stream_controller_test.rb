require 'test_helper'

class StreamControllerTest < ActionController::TestCase

  setup do
    sign_in User.first
  end

  test "should get realtime" do
    get :realtime, id: Prosumer.first.id
    assert_response :success
  end

end
