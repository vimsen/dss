class TargetClusteringController < ApplicationController

  def index

    @test = "Hello"

    @startDate = (Time.now - 1.day).beginning_of_hour
    @endDate = (Time.now).beginning_of_hour
    @interval = 1.hour
    @points = (@startDate.to_i .. @endDate.to_i).step(@interval).count
    @prosumer_category = 1

    @timestamps = (@startDate.to_i .. @endDate.to_i).step(@interval).map do |ts|
      Time.at(ts)
    end


  end

end