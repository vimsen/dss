class IntellenMockController < ApplicationController
  def getdata
     response.headers['Content-Type'] = 'application/json'
     
     startdate = params[:startdate]
     enddate = params[:enddate]
     interval = params[:interval]
     
     puts startdate, enddate, interval
     
     
     render :text => {:id => 123, :prosumer_id => 111131, :X => 115, :Y => "m.power"}.to_json
  end
end
