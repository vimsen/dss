require 'test_helper'

class DayAheadsControllerTest < ActionController::TestCase
  setup do
    @day_ahead = day_aheads(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:day_aheads)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create day_ahead" do
    assert_difference('DayAhead.count') do
      post :create, day_ahead: { date: @day_ahead.date, prosumer_id: @day_ahead.prosumer_id }
    end

    assert_redirected_to day_ahead_path(assigns(:day_ahead))
  end

  test "should show day_ahead" do
    get :show, id: @day_ahead
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @day_ahead
    assert_response :success
  end

  test "should update day_ahead" do
    patch :update, id: @day_ahead, day_ahead: { date: @day_ahead.date, prosumer_id: @day_ahead.prosumer_id }
    assert_redirected_to day_ahead_path(assigns(:day_ahead))
  end

  test "should destroy day_ahead" do
    assert_difference('DayAhead.count', -1) do
      delete :destroy, id: @day_ahead
    end

    assert_redirected_to day_aheads_path
  end
end
