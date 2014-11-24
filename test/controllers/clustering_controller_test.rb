require 'test_helper'

class ClusteringControllerTest < ActionController::TestCase
  test "should get select" do
    get :select
    assert_response :success
  end

  test "should get confirm" do
    get :confirm
    assert_response :success
  end

  test "should get save" do
    get :save
    assert_response :success
  end

end
