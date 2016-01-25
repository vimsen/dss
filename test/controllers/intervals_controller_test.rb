require 'test_helper'

class IntervalsControllerTest < ActionController::TestCase
  setup do
    @interval = intervals(:one)
    User.first.add_role "admin"
    sign_in User.first
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:intervals)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create interval" do
    assert_difference('Interval.count') do
      post :create, interval: { duration: @interval.duration, name: @interval.name }
    end

    assert_redirected_to interval_path(assigns(:interval))
  end

  test "should show interval" do
    get :show, id: @interval
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @interval
    assert_response :success
  end

  test "should update interval" do
    patch :update, id: @interval, interval: { duration: @interval.duration, name: @interval.name }
    assert_redirected_to interval_path(assigns(:interval))
  end

  test "should destroy interval" do
    assert_difference('Interval.count', 0) do # Should NOT destroy interval when it is referenced
      begin
        delete :destroy, id: @interval
      rescue

      end
    end

    assert_response 200
  end
end
