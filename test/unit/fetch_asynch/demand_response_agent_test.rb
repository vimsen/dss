require 'test_helper'

class DemandResponseAgentTest < ActiveSupport::TestCase

  setup do
    # Do nothing
  end

  test "Should post dr_event" do

    dr_obj = demand_responses(:one)
    agent = FetchAsynch::DemandResponseAgent.new
    agent.dr_activation dr_obj.id
    puts dr_obj.as_json(include: :dr_targets)
  end
end