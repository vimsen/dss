require 'test_helper'

class SlaItemsControllerTest < ActionController::TestCase
  setup do
    @sla_item = sla_items(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sla_items)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sla_item" do
    assert_difference('SlaItem.count') do
      post :create, sla_item: { bid_id: @sla_item.bid_id, interval_id: @sla_item.interval_id, price: @sla_item.price, timestamp: @sla_item.timestamp, volume: @sla_item.volume }
    end

    assert_redirected_to sla_item_path(assigns(:sla_item))
  end

  test "should show sla_item" do
    get :show, id: @sla_item
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @sla_item
    assert_response :success
  end

  test "should update sla_item" do
    patch :update, id: @sla_item, sla_item: { bid_id: @sla_item.bid_id, interval_id: @sla_item.interval_id, price: @sla_item.price, timestamp: @sla_item.timestamp, volume: @sla_item.volume }
    assert_redirected_to sla_item_path(assigns(:sla_item))
  end

  test "should destroy sla_item" do
    assert_difference('SlaItem.count', -1) do
      delete :destroy, id: @sla_item
    end

    assert_redirected_to sla_items_path
  end
end
