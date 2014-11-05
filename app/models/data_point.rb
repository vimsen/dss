class DataPoint < ActiveRecord::Base
    belongs_to :prosumer
    belongs_to :interval
    
end
