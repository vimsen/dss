class DayAhead < ActiveRecord::Base
  belongs_to :prosumer
  has_many :day_ahead_hours, dependent: :destroy
end
