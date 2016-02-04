require 'test_helper'

class DrActualsControllerTest < ActionController::TestCase
  setup do
    sign_in User.first
    @dr_actual = dr_actuals(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dr_actuals)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dr_actual" do
    assert_difference('DrActual.count') do
      post :create, dr_actual: { demand_response_id: @dr_actual.demand_response_id, prosumer_id: @dr_actual.prosumer_id, timestamp: @dr_actual.timestamp, volume: @dr_actual.volume }
    end

    assert_redirected_to dr_actual_path(assigns(:dr_actual))
  end

  test "should show dr_actual" do
    get :show, id: @dr_actual
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @dr_actual
    assert_response :success
  end

  test "should update dr_actual" do
    patch :update, id: @dr_actual, dr_actual: { demand_response_id: @dr_actual.demand_response_id, prosumer_id: @dr_actual.prosumer_id, timestamp: @dr_actual.timestamp, volume: @dr_actual.volume }
    assert_redirected_to dr_actual_path(assigns(:dr_actual))
  end

  test "should destroy dr_actual" do
    assert_difference('DrActual.count', -1) do
      delete :destroy, id: @dr_actual
    end

    assert_redirected_to dr_actuals_path
  end
end
