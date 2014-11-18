# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

users = User.create([{email: '***REMOVED***', password: '***REMOVED***'},
                     {email: '***REMOVED***', password: '***REMOVED***'}])
users.first.add_role "admin"


Interval.create([{ id: 1, duration: 900, name: '15 minutes'},
                 { id: 2, duration: 3600, name: '1 hour'},
                 { id: 3, duration: 86400, name: 'Daily'}])
 
clusters = Cluster.create([{name: "Cluster 1", description: "A testing cluster"}])

Prosumer.create([{name: "Prosumer 1", location: "Rio, Patras", cluster: clusters.first }, 
                 {name: "Prosumer 2", location: "Athens", cluster: clusters.first}])
                 
EnergyType.create([{name: 'solar'},{name: 'wind'},{name: 'hydro'},{name: 'geothermal'},{name: 'biomass'} ]) 