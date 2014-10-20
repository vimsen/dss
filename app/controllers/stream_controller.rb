require 'streamer/sse'

class StreamController < ApplicationController
  include ActionController::Live

  def addevent

    raise "Missing prosumer" if params[:id].nil?

    raise "Invalid prosumer id" if Prosumer.find_by_id(params[:id]).nil?

    power = rand(-100..100)
    measurement = Measurement.new(timeslot: DateTime.now, power: power, prosumer_id: params[:id] )
    measurement.save

    x = $bunny_channel.fanout("prosumer.#{params[:id]}")

    msg = {'id' => measurement.id, 'X' => measurement.timeslot.to_i, 'Y' => power}.to_json

    x.publish(msg)

    render nothing:true
  end

  def realtime
    response.headers['Content-Type'] = 'text/event-stream'
    sse = Streamer::SSE.new(response.stream)

    prosumer = Prosumer.find(params[:id])
    prosumer.measurements.where(timeslot: (Time.now - 2.days)..(Time.now + 1.day)).order(timeslot: :asc).last(200).each do |p|
      sse.write({'id' => p.id, 'X' => p.timeslot.to_i, 'Y' => p.power}.to_json, event: 'messages.create');
    end

    ActiveRecord::Base.connection.close

    x = $bunny_channel.fanout("prosumer.#{params[:id]}")
    q = $bunny_channel.queue("", :exclusive => true)
    q.bind(x)

    consumer = q.subscribe(:block => false) do |delivery_info, properties, data|
      sse.write(data, event: 'messages.create')
    end

    loop do
      sleep 10;
      sse.write("OK".to_json, event: 'messages.keepalive')
    end

  rescue IOError
  ensure
    consumer.cancel unless consumer.nil?
    sse.close
    puts "Stream closed."
  end
end
