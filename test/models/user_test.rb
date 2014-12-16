require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "the truth" do
    assert true
  end
   
  test "should not save user with email that exists" do
    email = User.first.email
    user1 = User.new email: email
    assert_not user1.save
  end
end
