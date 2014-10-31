VIMSEN Dashboard
==============

The web interface of the VMGA system
--------------

The VIMSEN project ...


What is implemented so far:
---------------------------

- Interface for managing the energy prosumers, available at http://vimsen.herokuapp.com/prosumers
- Interface for managing the measurements, available at http://vimsen.herokuapp.com/measurements
- Live plot for the energy prosumers, that includes real time prosumption data. This 
interface is available at http://vimsen.herokuapp.com/prosumers/ID, where ID is the ID of the prosumer
- Live JSON feed for each prosumer, available at http://vimsen.herokuapp.com/stream/1/realtime
- Interface for adding new prosumption data, through the link http://vimsen.herokuapp.com/stream/ID/addevent, where ID is the ID of the procumer.

Things to be implemented
-------------------------

- Prosumer cluster management
- Cluster aggregate feed and UI
- Alerts
- Short/Medium term forecasting
- Make a responsive menu

How it works
------------
The interface is a Ruby on Rails application. Postgres database is assumed.

The Puma web server is set as the testing server as it supports streaming responses. In order for real-time to work, we set `config.cache_classes` to `true`

The posting and subscription to events happens using the `bunny` RabbitMQ client for ruby.

How to test
-----------

 - visit the url: http://vimsen.herokuapp.com
 - to connect as a registered user, use the following: user: `***REMOVED***`, passwod: `***REMOVED***`
 - to connect as an administrator, use the following: user: `***REMOVED***`, passwod: `***REMOVED***` 



