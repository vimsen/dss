
#$bunny = Bunny.new("amqp://***REMOVED***:***REMOVED***@spotted-monkey.rmq.cloudamqp.com/***REMOVED***") 
$bunny = Bunny.new
$bunny.start
$bunny_channel = $bunny.create_channel
