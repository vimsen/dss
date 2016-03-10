require 'test_helper'
require 'test_helper_with_pros_and_market_data'
require 'database_cleaner'
require 'clustering/clustering_module'
require 'delorean'
require 'capybara'
require 'capybara/dsl'

Capybara.app = Rails.application.class
Capybara.default_driver = :rack_test
DatabaseCleaner.strategy = :truncation

class ClusteringIntegrationTest < ActionDispatch::IntegrationTestWithProsAndMarketData
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
      # 2.upto(2)
      ClusteringModule::algorithms.keys.size.times do |i|

        if ClusteringModule::algorithms.keys[i].to_s.include?("genetic")
          Rails.logger.debug "SKIPPING GENETIC - TOO SLOW"
          next
        end

        Rails.logger.debug "Testing algorithm: #{ClusteringModule::algorithms.keys[i]}"


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

        assert_includes([0,1], no_cluster.count, "Single list for unclustered prosumers")

        get_pros_count = ->(d) { d.all(:xpath, 'li[@id[starts-with(.,"prosumer_")]]').count }
        
        assert_equal 0, no_cluster.sum(&get_pros_count), "No unclustered prosumers"
        #         Rails.logger.debug page.all(:xpath, 'div[@id[starts-with(.,"prosumer_list_")]]').count
        assert_equal Prosumer.all.count,
                     page.all(:xpath, '//ul[@id[starts-with(.,"prosumer_list_")]]')
                         .sum(&get_pros_count),
                     "All prosumers should be in a cluster"
        assert_difference('Clustering.count') do
          click_button 'Confirm'
        end
        assert_match(/^\/clusterings\/\d+/, current_path, "Should be on clustering view page")

        total_penalties_before = page.first(:xpath, '//dt[text()="Total sum (€):"]/following::dd[1]').text.split.last.to_f
        total_penalties_after = page.first(:xpath, '//dt[text()="Total aggr. sum (€):"]/following::dd[1]').text.split.last.to_f
        total_penalty_reduction = page.first(:xpath, '//dt[text()="Improvement:"]/following::dd[1]').text.split.last.to_f

        Rails.logger.debug "before: #{total_penalties_before}, after: #{total_penalties_after}, perc: #{total_penalty_reduction }"

        assert_operator total_penalties_before, :>, 0, "Total penalties before should be positive"
        assert_operator total_penalties_after , :>, 0, "Total penalties after should be positive"
        assert_operator total_penalty_reduction , :>, 0, "Total penalty reduction should be positive"
        assert_operator total_penalties_after ,:<, total_penalties_before, "Penalties after should be larger than before"


        penalties_before = page.all(:xpath, '//table/tbody/tr/th[text()="sum"]/following::td[4]').map{|t| t.text.to_f}
        penalties_after = page.all(:xpath, '//table/tbody/tr/th[text()="aggr."]/following::td[4]').map{|t| t.text.to_f}
        penalty_reduction  = page.all(:xpath, '//table/tbody/tr/th[text()="Perc."]/following::td[4]').map{|t| t.text.to_f}

        Rails.logger.debug "penalties before: #{penalties_before}"
        Rails.logger.debug "penalties after: #{penalties_after}"
        Rails.logger.debug "penalty reduction: #{penalty_reduction}"

        assert_operator penalties_before.min, :>=, 0, "All penalties should be positive or zero"
        assert_operator penalties_after.min, :>=, 0, "All penalties should be positive or zero"
        assert_operator penalty_reduction.min, :>=, 0, "No cluster should be worse than before"


        assert_in_delta total_penalties_before,
                        penalties_before.sum,
                        total_penalties_before / 100,
                        "Penalties before should add up"
        assert_in_delta total_penalties_after,
                        penalties_after.sum,
                        total_penalties_after / 100,
                        "Penalties after should add up"
        assert_in_delta total_penalty_reduction,
                        penalties_before.zip(penalty_reduction).map{|a,b| a * b}.sum /
                            penalties_before.sum,
                        10,
                        "Penalties after should add up"

      end
    end
  end
end
