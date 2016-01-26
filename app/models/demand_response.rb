require 'fetch_asynch/demand_response_agent'

class DemandResponse < ActiveRecord::Base
  belongs_to :interval
  validates :interval, presence: true

  has_many :dr_targets, dependent: :destroy
  accepts_nested_attributes_for :dr_targets, allow_destroy: true
  validates_associated :dr_targets

  has_many :dr_planneds, dependent: :destroy
  has_many :dr_actuals, dependent: :destroy

  after_create do
    agent = FetchAsynch::DemandResponseAgent.new
    agent.dr_activation self.id
  end

  def starttime
    @startime ||= self.dr_targets.min_by{|t| t.timestamp}.timestamp unless self.dr_targets.empty?
    return @startime
  end

  def stoptime
    @stoptime ||= self.dr_targets.max_by{|t| t.timestamp}.timestamp unless self.dr_targets.empty?
    return @stoptime
  end

  def request_cached(channel)

    ActiveRecord::Base.connection_pool.with_connection do
      if self.dr_planneds.count < self.dr_targets.count ||
          self.dr_actuals.count < self.dr_targets.count
        agent = FetchAsynch::DemandResponseAgent.new
        agent.refresh_status self.id
      end
      {
          targets: Hash[self.dr_targets.map {|t| [t.timestamp.to_i * 1000, [t.timestamp.to_i * 1000, t.volume]] }],
          planned: Hash[self.dr_planneds.group(:timestamp).order(timestamp: :asc).sum(:volume).map {|k,v| [k.to_i * 1000, [k.to_i * 1000, v]]}],
          actual: Hash[self.dr_actuals.group(:timestamp).order(timestamp: :asc).sum(:volume).map {|k,v| [k.to_i * 1000, [k.to_i * 1000, v]]}]
      }
    end
  end

end
