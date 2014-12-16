require 'test_helper'

class EnergyTypesControllerTest < ActionController::TestCase
  setup do
    @energy_type = energy_types(:one)
    User.first.add_role "admin"
    sign_in User.first
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:energy_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create energy_type" do
    assert_difference('EnergyType.count') do
      post :create, energy_type: { name: @energy_type.name }
    end

    assert_redirected_to energy_type_path(assigns(:energy_type))
  end

  test "should show energy_type" do
    get :show, id: @energy_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @energy_type
    assert_response :success
  end

  test "should update energy_type" do
    patch :update, id: @energy_type, energy_type: { name: @energy_type.name }
    assert_redirected_to energy_type_path(assigns(:energy_type))
  end

  test "should destroy energy_type" do
    assert_difference('EnergyType.count', -1) do
      delete :destroy, id: @energy_type
    end

    assert_redirected_to energy_types_path
  end
end
