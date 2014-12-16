require 'test_helper'

class BuildingTypesControllerTest < ActionController::TestCase
  setup do
    @building_type = building_types(:one)
    User.first.add_role "admin"
    sign_in User.first
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:building_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create building_type" do
    assert_difference('BuildingType.count') do
      post :create, building_type: { name: @building_type.name }
    end

    assert_redirected_to building_type_path(assigns(:building_type))
  end

  test "should show building_type" do
    get :show, id: @building_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @building_type
    assert_response :success
  end

  test "should update building_type" do
    patch :update, id: @building_type, building_type: { name: @building_type.name }
    assert_redirected_to building_type_path(assigns(:building_type))
  end

  test "should destroy building_type" do
    assert_difference('BuildingType.count', -1) do
      delete :destroy, id: @building_type
    end

    assert_redirected_to building_types_path
  end
end
