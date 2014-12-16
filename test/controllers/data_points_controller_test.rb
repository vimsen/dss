require 'test_helper'

class DataPointsControllerTest < ActionController::TestCase
  setup do
    @data_point = data_points(:one)
    User.first.add_role "admin"
    sign_in User.first
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:data_points)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create data_point" do
    assert_difference('DataPoint.count') do
      post :create, data_point: { consumption: @data_point.consumption, dr: @data_point.dr, f_consumption: @data_point.f_consumption, f_production: @data_point.f_production, f_storage: @data_point.f_storage, f_timestamp: @data_point.f_timestamp, interval_id: @data_point.interval_id, production: @data_point.production, prosumer_id: @data_point.prosumer_id, reliability: @data_point.reliability, storage: @data_point.storage, timestamp: @data_point.timestamp }
    end

    assert_redirected_to data_point_path(assigns(:data_point))
  end

  test "should show data_point" do
    get :show, id: @data_point
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @data_point
    assert_response :success
  end

  test "should update data_point" do
    patch :update, id: @data_point, data_point: { consumption: @data_point.consumption, dr: @data_point.dr, f_consumption: @data_point.f_consumption, f_production: @data_point.f_production, f_storage: @data_point.f_storage, f_timestamp: @data_point.f_timestamp, interval_id: @data_point.interval_id, production: @data_point.production, prosumer_id: @data_point.prosumer_id, reliability: @data_point.reliability, storage: @data_point.storage, timestamp: @data_point.timestamp }
    assert_redirected_to data_point_path(assigns(:data_point))
  end

  test "should destroy data_point" do
    assert_difference('DataPoint.count', -1) do
      delete :destroy, id: @data_point
    end

    assert_redirected_to data_points_path
  end
end
