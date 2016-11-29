class DemandResponseProsumer < ActiveRecord::Base
  belongs_to :demand_response
  belongs_to :prosumer

  enum drp_type: [ :primary, :secondary ]
end
