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

BuildingType.create([{name: 'School'}, {name: 'Domestic'}, {name: 'SME'}])

school = BuildingType.find(1)
domestic = BuildingType.find(2)
sme = BuildingType.find(3)

ConnectionType.create([{name: '2G'},{name: '3G'},{name: '4G'},{name: 'ADSL'},{name: 'Cable'}])
adsl = ConnectionType.find(4)

Prosumer.create([ {name: "Prosumer 01", cluster: clusters.first, intelen_id: 1, building_type: domestic, connection_type: adsl, location_x: 35.508545, location_y: 24.016015},
                  {name: "Prosumer 02", cluster: clusters.first, intelen_id: 2, building_type: school, connection_type: adsl, location_x: 37.834419, location_y: 23.796322},
                  {name: "Prosumer 03", cluster: clusters.first, intelen_id: 3, building_type: school, connection_type: adsl, location_x: 37.983715, location_y: 23.729309},
                  {name: "Prosumer 04", cluster: clusters.first, intelen_id: 4, building_type: school, connection_type: adsl, location_x: 38.029222, location_y: 23.801853},
                  {name: "Prosumer 05", cluster: clusters.first, intelen_id: 5, building_type: school, connection_type: adsl, location_x: 38.018877, location_y: 23.789665},
                  {name: "Prosumer 06", cluster: clusters.first, intelen_id: 6, building_type: school, connection_type: adsl, location_x: 38.009410, location_y: 23.776104},
                  {name: "Prosumer 07", cluster: clusters.first, intelen_id: 7, building_type: school, connection_type: adsl, location_x: 38.035644, location_y: 23.834726},
                  {name: "Prosumer 08", cluster: clusters.first, intelen_id: 8, building_type: school, connection_type: adsl, location_x: 38.036929, location_y: 23.738167},
                  {name: "Prosumer 09", cluster: clusters.first, intelen_id: 9, building_type: school, connection_type: adsl, location_x: 38.044635, location_y: 23.769152},
                  {name: "Prosumer 10", cluster: clusters.first, intelen_id: 10, building_type: school, connection_type: adsl, location_x: 38.065316, location_y: 23.794386},
                  {name: "Prosumer 11", cluster: clusters.first, intelen_id: 11, building_type: school, connection_type: adsl, location_x: 38.004811, location_y: 23.800651},
                  {name: "Prosumer 12", cluster: clusters.first, intelen_id: 12, building_type: school, connection_type: adsl, location_x: 37.969635, location_y: 23.761169},
                  {name: "Prosumer 13", cluster: clusters.first, intelen_id: 13, building_type: school, connection_type: adsl, location_x: 37.964357, location_y: 23.720829},
                  {name: "Prosumer 14", cluster: clusters.first, intelen_id: 14, building_type: school, connection_type: adsl, location_x: 37.939753, location_y: 23.733791},
                  {name: "Prosumer 15", cluster: clusters.first, intelen_id: 15, building_type: school, connection_type: adsl, location_x: 37.953832, location_y: 23.693194},
                  {name: "Prosumer 16", cluster: clusters.first, intelen_id: 16, building_type: school, connection_type: adsl, location_x: 37.965539, location_y: 23.658089},
                  {name: "Prosumer 17", cluster: clusters.first, intelen_id: 17, building_type: school, connection_type: adsl, location_x: 37.937587, location_y: 23.644785},
                  {name: "Prosumer 18", cluster: clusters.first, intelen_id: 18, building_type: school, connection_type: adsl, location_x: 37.920730, location_y: 23.710875},
                  {name: "Prosumer 19", cluster: clusters.first, intelen_id: 19, building_type: domestic, connection_type: adsl, location_x: 37.903665, location_y: 23.748297},
                  {name: "Prosumer 20", cluster: clusters.first, intelen_id: 20, building_type: domestic, connection_type: adsl, location_x: 37.949297, location_y: 23.749584},
                  {name: "Prosumer 21", cluster: clusters.first, intelen_id: 21, building_type: domestic, connection_type: adsl, location_x: 37.954102, location_y: 23.730015},
                  {name: "Prosumer 22", cluster: clusters.first, intelen_id: 22, building_type: domestic, connection_type: adsl, location_x: 37.978259, location_y: 23.725466},
                  {name: "Prosumer 23", cluster: clusters.first, intelen_id: 23, building_type: domestic, connection_type: adsl, location_x: 38.000515, location_y: 23.712248},
                  {name: "Prosumer 24", cluster: clusters.first, intelen_id: 24, building_type: domestic, connection_type: adsl, location_x: 38.002409, location_y: 23.729500},
                  {name: "Prosumer 25", cluster: clusters.first, intelen_id: 25, building_type: domestic, connection_type: adsl, location_x: 38.027767, location_y: 23.736195},
                  {name: "Prosumer 26", cluster: clusters.first, intelen_id: 26, building_type: domestic, connection_type: adsl, location_x: 38.041017, location_y: 23.691477},
                  {name: "Prosumer 27", cluster: clusters.first, intelen_id: 27, building_type: domestic, connection_type: adsl, location_x: 38.076430, location_y: 23.809237},
                  {name: "Prosumer 28", cluster: clusters.first, intelen_id: 28, building_type: domestic, connection_type: adsl, location_x: 38.062375, location_y: 23.836016},
                  {name: "Prosumer 29", cluster: clusters.first, intelen_id: 29, building_type: domestic, connection_type: adsl, location_x: 38.020897, location_y: 23.824370},
                  {name: "Prosumer 30", cluster: clusters.first, intelen_id: 30, building_type: domestic, connection_type: adsl, location_x: 38.044066, location_y: 23.762587},
                  {name: "Prosumer 31", cluster: clusters.first, intelen_id: 31, building_type: domestic, connection_type: adsl, location_x: 38.015671, location_y: 23.750914},
                  {name: "Prosumer 32", cluster: clusters.first, intelen_id: 32, building_type: domestic, connection_type: adsl, location_x: 37.985371, location_y: 23.743446},
                  {name: "Prosumer 33", cluster: clusters.first, intelen_id: 33, building_type: domestic, connection_type: adsl, location_x: 37.957562, location_y: 23.699072},
                  {name: "Prosumer 34", cluster: clusters.first, intelen_id: 34, building_type: domestic, connection_type: adsl, location_x: 37.949576, location_y: 23.681991},
                  {name: "Prosumer 35", cluster: clusters.first, intelen_id: 35, building_type: sme, connection_type: adsl, location_x: 38.047130, location_y: 23.799947},
                  {name: "Prosumer 36", cluster: clusters.first, intelen_id: 36, building_type: sme, connection_type: adsl, location_x: 37.990407, location_y: 23.727710},
                  {name: "Prosumer 37", cluster: clusters.first, intelen_id: 37, building_type: sme, connection_type: adsl, location_x: 38.000350, location_y: 23.746764}
])
                 
EnergyType.create([{name: 'solar'},{name: 'wind'},{name: 'hydro'},{name: 'geothermal'},{name: 'biomass'} ])

Meter.create mac: '220590338055311'

