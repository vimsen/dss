class SlaItem < ActiveRecord::Base
  belongs_to :bid
  belongs_to :interval
end
