require 'test_helper'

class ProsumersControllerTest < ActionController::TestCase
  setup do
    @prosumer = prosumers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:prosumers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create prosumer" do
    assert_difference('Prosumer.count') do
      post :create, prosumer: { location: @prosumer.location, name: @prosumer.name }
    end

    assert_redirected_to prosumer_path(assigns(:prosumer))
  end

  test "should show prosumer" do
    get :show, id: @prosumer
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @prosumer
    assert_response :success
  end

  test "should update prosumer" do
    patch :update, id: @prosumer, prosumer: { location: @prosumer.location, name: @prosumer.name }
    assert_redirected_to prosumer_path(assigns(:prosumer))
  end

  test "should destroy prosumer" do
    assert_difference('Prosumer.count', -1) do
      delete :destroy, id: @prosumer
    end

    assert_redirected_to prosumers_path
  end
end
