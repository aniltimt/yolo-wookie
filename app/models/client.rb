class Client < ActiveRecord::Base
  belongs_to :user

  def ==(other)
    self.email == other.email && self.name == other.name && self.password == other.password && self.api_key == other.api_key
  end
end
