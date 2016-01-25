require 'test_helper'

class DemandResponsesControllerTest < ActionController::TestCase
  setup do
    sign_in User.first
    @demand_response = demand_responses(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:demand_responses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create demand_response" do
    assert_difference('DemandResponse.count') do
      post :create, demand_response: { interval_id: @demand_response.interval_id }
      # puts "AAAAAAAAAAAAAAAAA", @response
    end

    assert_redirected_to demand_response_path(assigns(:demand_response))
  end

  test "should show demand_response" do
    get :show, id: @demand_response
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @demand_response
    assert_response :success
  end

  test "should update demand_response" do
    patch :update, id: @demand_response, demand_response: { interval_id: @demand_response.interval_id }
    assert_redirected_to demand_response_path(assigns(:demand_response))
  end

  test "should destroy demand_response" do
    assert_difference('DemandResponse.count', -1) do
      delete :destroy, id: @demand_response
    end

    assert_redirected_to demand_responses_path
  end

  test "index with token authentication via query params" do
    sign_out User.first
    get :index, { user_email: users(:one).email, user_token: users(:one).authentication_token, format: :json }
    puts @request.parameters
    puts @response.body
    assert_response :success
  end

  test "index with token authentication via request headers" do
    sign_out User.first

    @request.headers['X-User-Email'] = users(:one).email
    @request.headers['X-User-Token'] = users(:one).authentication_token

    get :index, format: :json
    assert_response :success
  end
end
