require 'test_helper'

class IntellenMockControllerTest < ActionController::TestCase
  test "should get getdata" do
    User.first.add_role "admin"
    sign_in User.first
    get :getdata, prosumers: Prosumer.first.id, startdate: Time.now - 1.day,
        enddate: Time.now, interval: Interval.first.duration
    assert_response :success
  end

end
