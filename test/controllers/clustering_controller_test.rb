require 'test_helper'

class ClusteringControllerTest < ActionController::TestCase

  def setup
    @controller = ClusteringsController.new
    sign_in User.first
  end

  test "should get index" do

    get :index
    assert_response :success
  end

  test "should get select" do
    get :select
    assert_response :success
  end

  test "should get confirm" do
    post :confirm, algorithm: :energy_type
    assert_response :success
  end

end
