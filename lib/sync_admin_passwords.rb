require 'httparty'

class SyncAdminPasswords
  include HTTParty

  base_uri case Rails.env.to_s
    when 'production'; 'https://pre-production.digital-footsteps.com'
    when 'qa'; 'http://qa.digital-footsteps.com'
    when 'development'; 'localhost:3001'
  end

  default_timeout 60

  def self.sync(options)
    prev_password = options[:prev_password]
    password      = options[:password]
    salt          = options[:salt]

    raise "Previous password or current password is not set" if prev_password.blank? || password.blank?
    #Rails.logger.warn 'posting new admin password - ' + password.inspect
    resp = self.post("/admin/login/change", :body => {:prev_password => prev_password, :password => password, :salt => salt})
    Rails.logger.warn 'resp - ' + resp.body.inspect
  end
end
