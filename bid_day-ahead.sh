#!/bin/bash
rails runner -e development '
        BidDayAheadJob.perform_now(
                prosumers: Prosumer.where(id: [63, 62, 61, 60]),
#                starttime: "2015-11-09 11:45:00 +0200".to_datetime
         )'
