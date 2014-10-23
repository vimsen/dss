require 'yaml'
config = YAML.load_file('config/rabbitmq.yml')
 
$bunny = Bunny.new(:host => config[Rails.env]["host"],
        :vhost => config[Rails.env]["vhost"],
        :user => config[Rails.env]["user"],
        :password => config[Rails.env]["password"],
)

$bunny.start
$bunny_channel = $bunny.create_channel
