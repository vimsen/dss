require 'test_helper'

class StreamControllerTest < ActionController::TestCase
  test "should get addevent" do
    get :addevent
    assert_response :success
  end

  test "should get realtime" do
    get :realtime
    assert_response :success
  end

end
