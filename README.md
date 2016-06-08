VIMSEN DSS Dashboard
==============

The web interface of the DSS component VMGA system
--------------

The VIMSEN project (http://www.ict-vimsen.eu) aims at optimizing the operation of the smart grid, by enabling small-scale produres
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

