class ClientsSync
  include HTTParty

  class_attribute :clients_list, :responce

  #base_uri 'http://df.digital-footsteps.com'
  base_uri case Rails.env.to_s
    when 'production'; 'https://pre-production.digital-footsteps.com'
    when 'qa'; 'http://qa.digital-footsteps.com'
    when 'development'; 'localhost:3001'
  end

  default_timeout 60

  def self.request_clients_list
    self.responce = self.get("/v1/clients.js", :basic_auth => {:username => TB_SYNC_LOGIN, :password => TB_SYNC_PASSWD}).body
  end

  def self.parse_clients_list
    self.clients_list = JSON.parse(self.responce)
  end

  def self.sync
    self.clients_list.each do |market_client|
      market_client = market_client['client']
      local_client = Client.find_by_api_key(market_client['api_key'])
      if !local_client
        local_client = Client.create!(:email => market_client['email'], :name => market_client['name'], :api_key => market_client['api_key'], :market_client_id => market_client['id'], :password => market_client['password'])
        
        # creating regular user for TB 
        user = User.create!(:email => local_client['email'], :password => local_client['password'], :password_confirmation => local_client['password'], :login => local_client['name'], :role => "client")
        user.client = local_client
      else
        if local_client != market_client
          local_client.update_attributes(:email => market_client['email'], :name => market_client['name'], :api_key => market_client['api_key'], :market_client_id => market_client['id'], :password => market_client['password'])
          local_client.reload
          local_client.user.update_attributes(:email => local_client.email, :password => local_client.password, :password_confirmation => local_client.password, :login => local_client.name, :remember_token => nil, :remember_created_at => nil)
        end
      end
    end
  end

  def self.run
    request_clients_list
    parse_clients_list
    sync
  end
end
