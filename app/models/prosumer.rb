class Prosumer < ActiveRecord::Base
  has_many :measurements, dependent: :destroy
  belongs_to :cluster
  resourcify
  
  has_and_belongs_to_many :users
end
