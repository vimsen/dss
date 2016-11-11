require 'test_helper'
require 'test_helper_with_prosumption_data'

class DemandResponseAgentTest < ActiveSupport::TestCaseWithProsumptionData

  setup do
    # Do nothing
    @dr_obj = demand_responses(:one)
    @agent = FetchAsynch::DemandResponseAgent.new
  end

  test "Should post dr_event" do

    @agent = FetchAsynch::DemandResponseAgent.new
    @agent.dr_activation @dr_obj.id, nil, prosumer_categories(:one)

    @dr_obj.reload
    assert_not_nil @dr_obj.plan_id, "Plan id should not be nil"
    assert_operator 0, :<, @dr_obj.plan_id, "Plan id should be a positive number"

    @agent.refresh_status @dr_obj.id

    @dr_obj.reload
    # assert_operator 0, :<, @dr_obj.dr_planneds.count, "We should get some plans"
    # assert_operator 0, :<, @dr_obj.dr_actuals.count, "We should get some actuals"



  end

end