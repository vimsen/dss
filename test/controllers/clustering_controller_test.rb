require 'test_helper'
require 'test_helper_with_prosumption_data'
require 'delorean'

class ClusteringControllerTest < ActionController::TestCaseWithProsumptionData

  def setup
    @controller = ClusteringsController.new
    sign_in User.first
  end

  test "should get index" do

    get :index
    assert_response :success
  end

  test "should get select" do
    get :select
    assert_response :success
  end

  test "should post confirm energy_type" do
    post :confirm, algorithm: :energy_type
    assert_response :success
  end

  test "should post confirm building_type" do
    post :confirm, algorithm: :building_type
    assert_response :success
  end

  test "should post confirm connection_type" do
    post :confirm, algorithm: :connection_type
    assert_response :success
  end

  test "should post confirm location" do
    post :confirm, algorithm: :location, kappa: 5
    assert_response :success
  end

  test "should post confirm dr" do
    post :confirm, algorithm: :dr, kappa: 5
    assert_response :success
  end

  test "should post confirm genetic" do
    # Commenting out Delorean ,because it makes the test too slow
    Delorean.time_travel_to(@trainend) do
      post :confirm, algorithm: :genetic, kappa: 5
      assert_response :success
    end
  end

  test "should post confirm positive_error_spectral_clustering" do
    Delorean.time_travel_to(@trainend) do
      post :confirm, algorithm: :positive_error_spectral_clustering, kappa: 5
      assert_response :success
    end
  end

  test "should post confirm negative_error_spectral_clustering" do
    Delorean.time_travel_to(@trainend) do
      post :confirm, algorithm: :negative_error_spectral_clustering, kappa: 5
      assert_response :success
    end
  end

  test "should post confirm positive_consumption_spectral_clustering" do
    Delorean.time_travel_to(@trainend) do
      post :confirm, algorithm: :positive_consumption_spectral_clustering, kappa: 5
      assert_response :success
    end
  end

  test "should post confirm negative_consumption_spectral_clustering" do
    Delorean.time_travel_to(@trainend) do
      post :confirm, algorithm: :negative_consumption_spectral_clustering, kappa: 5
      assert_response :success
    end
  end


end
