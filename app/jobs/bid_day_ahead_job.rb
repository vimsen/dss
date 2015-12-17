class BidDayAheadJob < ActiveJob::Base
  queue_as :default

  def perform(*args)

    puts "The number of data points is #{DataPoint.count}"
    # Do something later
  end
end
