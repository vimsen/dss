require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:two)
    User.first.add_role "admin"
    sign_in User.first
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user" do
#    assert_difference('User.count') do
#      post :create, user: { email: 'unique@email.com', prosumers: @user.prosumers.map{|p| p.id}, roles: @user.roles.map{|p| p.id} }
#    end

#    assert_redirected_to user_path(assigns(:user))
  end

  test "should show user" do
    get :show, id: @user
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @user
    assert_response :success
  end

  test "should update user" do
    puts "prosumers: ", @user.prosumers
    
    patch :update, id: @user, user: { email: @user.email, prosumers: @user.prosumers.map{|p| p.id}, roles: @user.roles.map{|p| p.id} }
    assert_redirected_to user_path(assigns(:user))
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete :destroy, id: @user
    end

    assert_redirected_to users_path
  end
end
