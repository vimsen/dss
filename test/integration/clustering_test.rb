require 'test_helper'
require 'database_cleaner'
require 'clustering/clustering_module'

Capybara.app = Rails.application.class
Capybara.default_driver = :rack_test
DatabaseCleaner.strategy = :truncation

class ClusteringTest < ActionDispatch::IntegrationTestWithProsumptionData
  include Capybara::DSL
  include Warden::Test::Helpers
  # include Devise::TestHelpers

  self.use_transactional_fixtures = false

  setup do
    DatabaseCleaner.start
    login_as User.first    # or Factory(:user....)
  end

  teardown do
    DatabaseCleaner.clean
  end

  test "run spectral algorithm" do
    Capybara.current_driver = :selenium
    visit '/clusterings/select'

    assert page.has_selector?('#algorithm'), "There should be an #algorithm input"

    # expect(page).to have_selector('#algorithm', visible: true)

    assert(find('#algorithm'), "There should be an #algorithm input")

    assert page.has_select?('algorithm', :options => ClusteringModule::algorithms.map{|k,v| v[:string]}),
           "Should have all options available"

    assert(current_path == '/clusterings/select', "Should be on select page")

    select "Positive Error Spectral Clustering", :from => "algorithm"
    click_button 'Select'
    assert(current_path == '/clusterings/confirm', "Should be on confirm page")


    #fill_in 'user_email', :with => 'player@example.com'
    #fill_in 'user_password', :with => 'password'
    #click_button 'Log in'

  end

end