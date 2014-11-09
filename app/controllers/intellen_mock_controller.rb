class IntellenMockController < ApplicationController
  def getdata
    
    puts "========= IN GETDATA =================="
    
    response.headers['Content-Type'] = 'application/json'

    prosumers = params[:prosumers]
    startdate = params[:startdate].to_i
    enddate = params[:enddate].to_i
    interval = params[:interval].to_i
    puts "startdate: #{startdate}"
    puts "enddate  : #{enddate}"
    puts "interval: #{interval}"

    result = []

    (startdate .. enddate).step(interval) do |t|
      prosumers.split(",").each do |p|
        result.push({
          :timestamp => t,
          :prosumer_id => p.to_i,
          :interval => interval,
          :actual => {
            :production => rand(0..100),
            :consumption => rand(0..100),
            :storage => rand(0..100)
          },
          :forecast => {
            :timestamp => t + interval,
            :production => rand(0..100),
            :consumption => rand(0..100),
            :storage => rand(0..100)
          },
          :dr => rand(0..1),
          :reliability => rand(0..1)
        })  
      end
    end

    # puts prosumer, startdate, enddate, interval

    render :text => result.to_json
  end
end
