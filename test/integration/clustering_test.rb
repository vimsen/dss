require 'test_helper'
require 'database_cleaner'
require 'clustering/clustering_module'
require 'delorean'

Capybara.app = Rails.application.class
Capybara.default_driver = :rack_test
DatabaseCleaner.strategy = :truncation

class ClusteringTest < ActionDispatch::IntegrationTestWithProsAndMarketData
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

    Capybara.register_driver :selenium_15_min do |app|
      profile = Selenium::WebDriver::Firefox::Profile.new
      client = Selenium::WebDriver::Remote::Http::Default.new
      client.timeout = 60 * 15 # instead of the default 60
      Capybara::Selenium::Driver.new(app, browser: :firefox,
                                     profile: profile,
                                     http_client: client)
    end

    Capybara.current_driver = :selenium_15_min

    Delorean.time_travel_to(@trainend) do
      # ClusteringModule::algorithms.keys.size
      1.times do |i|
        visit clusterings_select_path
        assert page.has_selector?('#algorithm'), "There should be an #algorithm input"
        assert(find('#algorithm'), "There should be an #algorithm input")
        assert page.has_select?('algorithm', :options => ClusteringModule::algorithms.map{|k,v| v[:string]}),
               "Should have all options available"
        assert(current_path == clusterings_select_path, "Should be on select page")

        select ClusteringModule::algorithms.values[i][:string], :from => "algorithm"
        click_button 'Select'
        assert(current_path == clusterings_confirm_path, "Should be on confirm page for algorithn '#{ClusteringModule::algorithms.values[i][:string]}'")


        no_cluster = page.all(:xpath, '//ul[@id="prosumer_list_-1"]')

        assert_equal 1, no_cluster.count, "Single list for unclustered prosumers"

        get_prosumers = Proc.new {|d| d.all(:xpath, 'li[@id[starts-with(.,"prosumer_")]]').count }
        
        assert_equal 0, no_cluster.sum{|d| get_prosumers.call(d) }, "No unclustered prosumers"
        #         puts page.all(:xpath, 'div[@id[starts-with(.,"prosumer_list_")]]').count
        assert_equal Prosumer.all.count, 
                    (page.all(:xpath, '//ul[@id[starts-with(.,"prosumer_list_")]]').sum do |ul|
                        get_prosumers.call(ul)
                    end),
                    "All prosumers should be in a cluster"
        click_button 'Confirm'
        assert_match(/^\/clusterings\/\d+/, current_path, "Should be on clustering view page")

      end
    end
  end
end
