class Forecast < ActiveRecord::Base
  belongs_to :prosumer
  belongs_to :interval

  enum forecast_type: [ :day_ahead, :inra_day, :real_time ]
end
