class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
         
  has_and_belongs_to_many :prosumers

  def getNotAssignedRoles
    result = Role.all
    result.reject { |r| self.has_role? r.name }
  end
end
