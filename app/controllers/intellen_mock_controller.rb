class IntellenMockController < ApplicationController
  def getdata
    
    puts "========= IN GETDATA =================="
    
    response.headers['Content-Type'] = 'application/json'

    prosumer = params[:prosumer]
    startdate = params[:startdate].to_i
    enddate = params[:enddate].to_i
    interval = params[:interval].to_i
    puts "startdate: #{startdate}"
    puts "enddate  : #{enddate}"
    puts "interval: #{interval}"

    result = []

    (startdate .. enddate).step(interval) do |t|

      result.push({
        :timestamp => t,
        :prosumer_id => params[:prosumer],
        :interval => interval,
        :actual => {
          :production => rand(-100..100),
          :consumption => rand(-100..100),
          :storage => rand(-100..100)
        },
        :forecast => {
          :timestamp => t + interval,
          :production => rand(-100..100),
          :consumption => rand(-100..100),
          :storage => rand(-100..100)
        },
        :dr => rand(0..1),
        :reliability => rand(0..1)
      })
    end

    # puts prosumer, startdate, enddate, interval

    render :text => result.to_json
  end
end
