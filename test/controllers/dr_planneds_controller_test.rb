require 'test_helper'

class DrPlannedsControllerTest < ActionController::TestCase
  setup do
    sign_in User.first
    @dr_planned = dr_planneds(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dr_planneds)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dr_planned" do
    assert_difference('DrPlanned.count') do
      post :create, dr_planned: { demand_response_id: @dr_planned.demand_response_id, prosumer_id: @dr_planned.prosumer_id, timestamp: @dr_planned.timestamp, volume: @dr_planned.volume }
    end

    assert_redirected_to dr_planned_path(assigns(:dr_planned))
  end

  test "should show dr_planned" do
    get :show, id: @dr_planned
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @dr_planned
    assert_response :success
  end

  test "should update dr_planned" do
    patch :update, id: @dr_planned, dr_planned: { demand_response_id: @dr_planned.demand_response_id, prosumer_id: @dr_planned.prosumer_id, timestamp: @dr_planned.timestamp, volume: @dr_planned.volume }
    assert_redirected_to dr_planned_path(assigns(:dr_planned))
  end

  test "should destroy dr_planned" do
    assert_difference('DrPlanned.count', -1) do
      delete :destroy, id: @dr_planned
    end

    assert_redirected_to dr_planneds_path
  end
end
