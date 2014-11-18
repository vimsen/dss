class IntellenMockController < ApplicationController
  
  def getdayahead
    response.headers['Content-Type'] = 'application/json'
    
    prosumers = params[:prosumers]
    date = params[:date]
    
    
    result = prosumers.split(",").map do |p|
      {
            :prosumer_id => p.to_i,
            :date => date,
            :points => 0.upto(23).map do |t|
              {
                :time => t,
                :production => rand * 100,
                :consumption => rand * 100
              }
            end
      }
    end
    render :text => result.to_json
  end
  
  def getdata
    
    puts "========= IN GETDATA =================="
    
    response.headers['Content-Type'] = 'application/json'

    prosumers = params[:prosumers]
    startdate = DateTime.parse(params[:startdate])
    enddate = DateTime.parse(params[:enddate])
    interval = params[:interval].to_i
    puts "prosumers: #{prosumers}"
    puts "startdate: #{startdate}"
    puts "enddate  : #{enddate}"
    puts "interval: #{interval}"

    result = []

    (startdate.to_i .. enddate.to_i).step(interval) do |t|
      prosumers.split(",").each do |p|
        result.push({
          :timestamp => Time.at(t).to_datetime,
          :prosumer_id => p.to_i,
          :interval => interval,
          :actual => {
            :production => rand * 100,
            :consumption => rand * 100,
            :storage => rand * 100
          },
          :forecast => {
            :timestamp => Time.at(t + interval).to_datetime,
            :production =>  rand * 100,
            :consumption =>  rand * 100,
            :storage =>  rand * 100
          },
          :dr => rand,
          :reliability => rand
        })  
      end
    end

    # puts prosumer, startdate, enddate, interval

    render :text => result.to_json
  end
end
