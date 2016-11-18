#!/bin/bash
rails runner -e development '
        BidDayAheadJob.perform_now(
                prosumers: Prosumer.where(prosumer_category_id: 1),
#                starttime: "2015-11-09 11:45:00 +0200".to_datetime
         )'
