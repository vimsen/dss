class Bid < ActiveRecord::Base
  has_many :sla_items, dependent: :destroy
  enum status: %i(submitted accepted rejected withdrawn)
end
