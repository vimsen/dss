require 'test_helper'
require 'test_helper_with_prosumption_data'

class DemandResponsesControllerTest < ActionController::TestCaseWithProsumptionData
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
      post :create, demand_response: { interval_id: @demand_response.interval_id, dr_targets_attributes: @demand_response.dr_targets.map{|t| {volume: t.volume, timestamp: t.timestamp}} }
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
    # puts @request.parameters
    # puts @response.body
    assert_response :success
  end

  test "index with token authentication via request headers" do
    sign_out User.first

    @request.headers['X-User-Email'] = users(:one).email
    @request.headers['X-User-Token'] = users(:one).authentication_token

    get :index, format: :json
    assert_response :success
  end

  test "should submit DR evant through the API" do
    sign_out User.first
   #  users(:one).add_role :admin

    starttime = DateTime.now + 1.hour

    newDRsignal = {
        interval_id: Interval.find_by_name("15 minutes").id,
        dr_targets_attributes: 10.times.map do | i |
          {
              volume: rand(5.0...50.0),
              timestamp: (starttime + (i * Interval.find_by_name("15 minutes").duration).seconds).to_s
          }
        end
    }

    json = ""
    assert_difference('DemandResponse.count') do
      puts demand_response: newDRsignal, user_email: users(:one).email, user_token: users(:one).authentication_token, format: :json
      post :create, demand_response: newDRsignal, user_email: users(:one).email, user_token: users(:one).authentication_token, format: :json
      puts @response.body
      json = JSON.parse @response.body
      puts @response.body
    end
    assert_response 201

    assert_equal newDRsignal[:interval_id], json["interval_id"]

    newDRsignal[:dr_targets_attributes].zip(json["dr_targets"]).each do |e,a|
      assert_equal DateTime.parse(e[:timestamp]), DateTime.parse(a["timestamp"])
      assert_in_delta e[:volume], a["volume"], 0.00001
    end

  end
end
