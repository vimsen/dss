require 'test_helper'
require 'database_cleaner'
require 'capybara'
require 'capybara/dsl'

Capybara.app = Rails.application.class
Capybara.default_driver = :rack_test
DatabaseCleaner.strategy = :truncation

class LoginTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  self.use_transactional_fixtures = false

  setup do
    DatabaseCleaner.start
    assert User.create! :password => 'password2', :password_confirmation => 'password2', :email => 'player@example.com'
    # or Factory(:user....)
  end

  teardown do
    DatabaseCleaner.clean
  end

  test "login user" do
    Capybara.current_driver = :selenium
    visit root_path
    assert_equal('/users/sign_in', current_path)
    fill_in 'user_email', :with => 'player@example.com'
    fill_in 'user_password', :with => 'password2'
    click_button 'Log in'

    find("strong", text: "VMGA DSS Platform researches:")
    assert_equal(root_path, current_path)
  end

end
