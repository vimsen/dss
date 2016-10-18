require 'test_helper'

class ForecastsControllerTest < ActionController::TestCase
  setup do
    @forecast = forecasts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:forecasts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create forecast" do
    assert_difference('Forecast.count') do
      post :create, forecast: { consumption: @forecast.consumption, forecast_time: @forecast.forecast_time, interval_id: @forecast.interval_id, production: @forecast.production, prosumer_id: @forecast.prosumer_id, storage: @forecast.storage, timestamp: @forecast.timestamp }
    end

    assert_redirected_to forecast_path(assigns(:forecast))
  end

  test "should show forecast" do
    get :show, id: @forecast
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @forecast
    assert_response :success
  end

  test "should update forecast" do
    patch :update, id: @forecast, forecast: { consumption: @forecast.consumption, forecast_time: @forecast.forecast_time, interval_id: @forecast.interval_id, production: @forecast.production, prosumer_id: @forecast.prosumer_id, storage: @forecast.storage, timestamp: @forecast.timestamp }
    assert_redirected_to forecast_path(assigns(:forecast))
  end

  test "should destroy forecast" do
    assert_difference('Forecast.count', -1) do
      delete :destroy, id: @forecast
    end

    assert_redirected_to forecasts_path
  end
end
