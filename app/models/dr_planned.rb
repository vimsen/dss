class DrPlanned < ActiveRecord::Base
  belongs_to :prosumer
  belongs_to :demand_response
end
