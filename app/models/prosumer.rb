class Prosumer < ActiveRecord::Base
  has_many :measurements, dependent: :destroy
  belongs_to :cluster
end
