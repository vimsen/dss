class Role < ActiveRecord::Base
  has_and_belongs_to_many :users, :join_table => :users_roles
  belongs_to :resource, :polymorphic => true

  scopify
  
  def getNotMembers
    result = User.all
    return result.reject { |u| u.has_role? self.name }
  end
end
