# The estimage for the hour of the specific day
class DayAheadHour < ActiveRecord::Base
  belongs_to :day_ahead
end
