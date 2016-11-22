#!/bin/bash
rails runner -e development '
        BidDayAheadJob.perform_now(
                prosumers: Prosumer.where(prosumer_category_id: 4),
                date: "21/11/2015".to_date
#                starttime: "2015-11-09 11:45:00 +0200".to_datetime
         )'
