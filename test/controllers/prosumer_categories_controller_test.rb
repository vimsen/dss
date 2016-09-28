require 'test_helper'

class ProsumerCategoriesControllerTest < ActionController::TestCase
  setup do
    @prosumer_category = prosumer_categories(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:prosumer_categories)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create prosumer_category" do
    assert_difference('ProsumerCategory.count') do
      post :create, prosumer_category: { description: @prosumer_category.description, name: @prosumer_category.name, real_time: @prosumer_category.real_time }
    end

    assert_redirected_to prosumer_category_path(assigns(:prosumer_category))
  end

  test "should show prosumer_category" do
    get :show, id: @prosumer_category
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @prosumer_category
    assert_response :success
  end

  test "should update prosumer_category" do
    patch :update, id: @prosumer_category, prosumer_category: { description: @prosumer_category.description, name: @prosumer_category.name, real_time: @prosumer_category.real_time }
    assert_redirected_to prosumer_category_path(assigns(:prosumer_category))
  end

  test "should destroy prosumer_category" do
    assert_difference('ProsumerCategory.count', -1) do
      delete :destroy, id: @prosumer_category
    end

    assert_redirected_to prosumer_categories_path
  end
end
