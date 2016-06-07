require 'test_helper'

class DrTargetsControllerTest < ActionController::TestCase
  setup do
    sign_in User.first
    @dr_target = dr_targets(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dr_targets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dr_target" do
    assert_difference('DrTarget.count') do
      post :create, dr_target: { demand_response_id: @dr_target.demand_response_id, timestamp: @dr_target.timestamp, volume: @dr_target.volume }
    end

    assert_redirected_to dr_target_path(assigns(:dr_target))
  end

  test "should show dr_target" do
    get :show, id: @dr_target
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @dr_target
    assert_response :success
  end

  test "should update dr_target" do
    patch :update, id: @dr_target, dr_target: { demand_response_id: @dr_target.demand_response_id, timestamp: @dr_target.timestamp, volume: @dr_target.volume }
    assert_redirected_to dr_target_path(assigns(:dr_target))
  end

  test "should destroy dr_target" do
    assert_difference('DrTarget.count', -1) do
      delete :destroy, id: @dr_target
    end

    assert_redirected_to dr_targets_path
  end
end
