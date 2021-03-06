require 'fetch_asynch/demand_response_agent'

class DemandResponse < ActiveRecord::Base
  belongs_to :interval
  validates :interval, presence: true

  has_many :dr_targets, dependent: :destroy
  accepts_nested_attributes_for :dr_targets, allow_destroy: true
  validates_associated :dr_targets

  belongs_to :prosumer_category

  has_many :dr_planneds, dependent: :destroy
  has_many :dr_actuals, dependent: :destroy

  has_many :demand_response_prosumers, dependent: :destroy
  has_many :prosumers, through: :demand_response_prosumers

  enum event_type: [:target_match, :urgent_cut, :planned_cut, :static_allocation, :greek_pilot_static ]


  after_commit :run_after_create, :on => :create

  def run_after_create
    agent = FetchAsynch::DemandResponseAgent.new
    agent.dr_activation self.reload, self.feeder_id, self.prosumer_category
  end

  def starttime
    @startime ||= self.dr_targets.min_by{|t| t.timestamp}.timestamp unless self.dr_targets.empty?
    return @startime
  end

  def stoptime
    @stoptime ||= self.dr_targets.max_by{|t| t.timestamp}.timestamp unless self.dr_targets.empty?
    return @stoptime
  end

  def dr_properties
    ActiveRecord::Base.connection_pool.with_connection do
      {
          targets: Hash[self.dr_targets.map {|t| [t.timestamp.to_i * 1000, [t.timestamp.to_i * 1000, t.volume]] }],
          planned: Hash[self.dr_planneds.group(:timestamp).order(timestamp: :asc).sum(:volume).map {|k,v| [k.to_i * 1000, [k.to_i * 1000, v]]}],
          actual: Hash[self.dr_actuals.where('volume > 0').group(:timestamp).order(timestamp: :asc).sum(:volume).map {|k,v| [k.to_i * 1000, [k.to_i * 1000, v]]}]
      }
    end
  end

  def request_cached(channel)
    ActiveRecord::Base.connection_pool.with_connection do
      if self.need_more_data
        agent = FetchAsynch::DemandResponseAgent.new
        agent.refresh_status self.id
        self.reload
      end
      dr_properties
    end
  end

  def need_more_data
    ActiveRecord::Base.connection_pool.with_connection do
      (self.dr_planneds.where('volume is not null').group(:timestamp).count.count< self.dr_targets.count ||
          self.dr_actuals.where('volume is not null').group(:timestamp).count.count < self.dr_targets.count) && !self.starttime.nil?
    end
  end
end
