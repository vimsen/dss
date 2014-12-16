require 'test_helper'

class EnergyPricesControllerTest < ActionController::TestCase
  setup do
    @energy_price = energy_prices(:one)
    User.first.add_role "admin"
    sign_in User.first
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:energy_prices)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create energy_price" do
    assert_difference('EnergyPrice.count') do
      post :create, energy_price: { date: @energy_price.date, dayhour: @energy_price.dayhour, price: @energy_price.price }
    end

    assert_redirected_to energy_price_path(assigns(:energy_price))
  end

  test "should show energy_price" do
    get :show, id: @energy_price
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @energy_price
    assert_response :success
  end

  test "should update energy_price" do
    patch :update, id: @energy_price, energy_price: { date: @energy_price.date, dayhour: @energy_price.dayhour, price: @energy_price.price }
    assert_redirected_to energy_price_path(assigns(:energy_price))
  end

  test "should destroy energy_price" do
    assert_difference('EnergyPrice.count', -1) do
      delete :destroy, id: @energy_price
    end

    assert_redirected_to energy_prices_path
  end
end
