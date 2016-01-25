class DemandResponse < ActiveRecord::Base
  belongs_to :interval
  validates :interval, presence: true

  has_many :dr_targets, dependent: :destroy
  accepts_nested_attributes_for :dr_targets, allow_destroy: true
  validates_associated :dr_targets

  has_many :dr_planneds, dependent: :destroy
  has_many :dr_actuals, dependent: :destroy
end
