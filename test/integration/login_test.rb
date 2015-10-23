require 'test_helper'
require 'database_cleaner'

Capybara.app = Rails.application.class
Capybara.default_driver = :rack_test
DatabaseCleaner.strategy = :truncation

class LoginTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  self.use_transactional_fixtures = false

  setup do
    DatabaseCleaner.start
    assert User.create! :password => 'password', :password_confirmation => 'password', :email => 'player@example.com'
    # or Factory(:user....)
  end

  teardown do
    DatabaseCleaner.clean
  end

  test "login user" do
    Capybara.current_driver = :selenium
    visit '/users/sign_in'
    fill_in 'user_email', :with => 'player@example.com'
    fill_in 'user_password', :with => 'password'
    click_button 'Log in'
    assert(current_path == root_path)
  end

end