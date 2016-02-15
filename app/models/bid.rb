class Bid < ActiveRecord::Base
  has_many :sla_items
end
