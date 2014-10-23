require 'yaml'
config = YAML.load_file('config/rabbitmq.yml')
 
puts "Conncting to RabbitMQ server at host: #{config[Rails.env]["host"]}"
$bunny = Bunny.new(config[Rails.env].with_indifferent_access)

$bunny.start
$bunny_channel = $bunny.create_channel
puts "Connected."
