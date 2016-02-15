class CheckBidStatusJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
    Bid.select("COUNT(sla_items.id) AS count_sla_items, bids.id AS bid_id")
        .joins("LEFT OUTER JOIN sla_items ON (sla_items.bid_id = bids.id)")
        .group("bids.id")
        .map do |b|
      b.count_sla_items
    end

  end
end
