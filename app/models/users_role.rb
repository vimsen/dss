# pretty much exclusively created for our fixtures to work
class UsersRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
end
