require 'test_helper'

class DayAheadHoursControllerTest < ActionController::TestCase
  setup do
    @day_ahead_hour = day_ahead_hours(:one)
    User.first.add_role "admin"
    sign_in User.first
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:day_ahead_hours)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create day_ahead_hour" do
    assert_difference('DayAheadHour.count') do
      post :create, day_ahead_hour: { consumption: @day_ahead_hour.consumption, day_ahead_id: @day_ahead_hour.day_ahead_id, production: @day_ahead_hour.production, time: @day_ahead_hour.time }
    end

    assert_redirected_to day_ahead_hour_path(assigns(:day_ahead_hour))
  end

  test "should show day_ahead_hour" do
    get :show, id: @day_ahead_hour
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @day_ahead_hour
    assert_response :success
  end

  test "should update day_ahead_hour" do
    patch :update, id: @day_ahead_hour, day_ahead_hour: { consumption: @day_ahead_hour.consumption, day_ahead_id: @day_ahead_hour.day_ahead_id, production: @day_ahead_hour.production, time: @day_ahead_hour.time }
    assert_redirected_to day_ahead_hour_path(assigns(:day_ahead_hour))
  end

  test "should destroy day_ahead_hour" do
    assert_difference('DayAheadHour.count', -1) do
      delete :destroy, id: @day_ahead_hour
    end

    assert_redirected_to day_ahead_hours_path
  end
end
