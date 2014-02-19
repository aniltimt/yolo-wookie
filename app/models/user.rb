class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :http_authenticatable, :token_authenticatable, :lockable, :timeoutable and :activatable
  devise :database_authenticatable, :recoverable,
         :rememberable, :trackable

  validates_presence_of :login, :password, :password_confirmation
  validates_confirmation_of :password

  # Setup accessible (or protected) attributes for your model
  attr_accessible :login, :email, :role, :password, :password_confirmation, :remember_me, :remember_token, :remember_created_at

  has_one :client

  has_many :tours
  has_many :ubertours
  has_many :locations
  has_many :media

  def self.find_for_authentication(conditions={})
    #conditions[:active] = true
    #find(:first, :conditions => conditions)
    find(:first, :conditions => ["BINARY login = ?", conditions["login"]])
    #super
  end

  def client?
    self.role == 'client'
  end

  def ubertours
    #self.tours.find(:all, :conditions => {:is_ubertour => true})
    Tour.ubertours.by_user(self)
  end
end
