VIMSEN DSS Dashboard
==============

The web interface of the DSS component VMGA system
--------------

The VIMSEN project (http://www.ict-vimsen.eu) aims at optimizing the operation of the smart grid, by enabling small-scale produsers
and consumers (i.e. prosumers) to participate in the energy market, through aggregation into virtual
micro-grids.

One of the major VIMSEN project’s objectives is to provide “Information
management and decision making technologies for the dynamic VMG creation in a way to
optimize the participants’ benefits and macro-grid perspectives”. The DSS platform is responsible
for orchestrating and efficiently managing the RES of multiple energy prosumers called as
VIMSEN Prosumers (VPs). It is also responsible for enabling the decentralized electricity
market supported by VIMSEN project. Furthermore, it provides the necessary information
tools and service engineering methodologies (based on the Web service technology) to
choose the micro-grids and the distributed energy sources within the VMG framework, to
handle the respective pricing policies and finally to activate the dynamic clustering
framework in order to update and evolve VMG associations according to the current energy
information, forecasting and demands. Finally, novel algorithms regarding the VMG groups’
formation/dynamic adaptation and VMG profiles’ management are designed, developed and
will be integrated in the DSS platform/toolkit. These algorithms take advantage of an
innovative hybrid cloud computing processing infrastructure (HCCI), which allows heavyprocessing
tasks/jobs to be executed in less time and thus real-time decision making
procedures to be realized, which is very important for the successful operation of the whole
VIMSEN system. DSS and HCCI reside at the Virtual Microgrid Aggregator’s (VMGA) side,
which acts as an intermediate business actor between: a) the market and energy system
operators (e.g. market operator, DSO, TSO, supplier, utility company) residing at the higher
level of VIMSEN architecture, and b) VIMSEN Prosumers (VPs) residing at the lower level of
VIMSEN architecture.



How it works
------------
The interface is a Ruby on Rails application. Postgres database is assumed.

The Puma web server is set as the testing server as it supports streaming responses. In order for real-time to work, we set `config.cache_classes` to `true`

The posting and subscription to events happens using the `bunny` RabbitMQ client for ruby.


Installation instructions
-------------------------
The DSS platform is implemented on Ruby on Rails, developed on linux, using Postgres as the database, and rabbitmq as the messaging framework. More specifically, the latest version of the platform has been built using the following:

  - Ruby version 2.2.3p173
  - Rails version 4.2.5
  - PostgreSQL version 9.3.13
  - Rabbitmq version 3.2.4

The current operation of the DSS platform depends on other VIMSEN components, namely:

  - the EDMS system,
  - the GDRMS system
  - the Market operator S/W agent
  - the DSO S/W agent
  - the BRP S/W agent

The procedure for installing the DSS module is the following:

  1. Install ruby and the rails framework. Detailed instruction for this may be found here: https://gorails.com/setup/ubuntu/14.10 
  2. Install postgresql and rabbitmq, using the following command: sudo apt-get install postgresql rabbitmq-server
  3. Clone the repository: git clone https://github.com/vimsen/dss.git, and enter the project directory
  4. Setup the configuration files in accordance with the sample files present in the config subdirectory (extension “.sample”). These sample files should be copied to the same directory but without the extension .sample, and then filled in with the appropriate information. Specifically, the config/database.yml contains information for the local DSS database, the config/rabbitmq.yml contains information for connecting to the rabbitmq queue, the config/vimsen_hosts.yml file contains information for connecting to the other VIMSEN components, and the config/cloud_engine.yml file contains information for connecting to the cloud services.
  5. After the config files have been filled in, the next step is to setup the database with rake db:create, rake db:migrate and rake db:seed.
  6. The server may be started with rails server.
  7. Tests may be run with rake test.

Note that in order for the DSS database to be populated with data, a connection with the EDMS system must be established. On the contrary, the tests may be executed using the data that is included in the test fixtures (without the need for the EDMS system). 
In the final release of the VIMSEN software will be demonstrated to cooperate with other VIMSEN subsystems, namely the EDMS for obtaining measurement data, the FMS for retrieving forecasts, and the GDRMS for implementing demand response commands. Deliverable D7.2.2 will present the integration activities between the different VIMSEN components.