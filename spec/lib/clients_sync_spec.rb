require 'spec_helper'

describe ClientsSync do
  before do
    @list_json = '[{"client":{"api_key":"QH86LEt42hjsDASLgzz9","created_at":"2011-11-21T16:18:14Z","email":"testee@example.com","id":1,"name":"Testeer","password":"!z$RdqW","updated_at":"2011-11-22T14:11:58Z"}},{"client":{"api_key":"ms6LOrgcgLTO6oBUaUTI","created_at":"2011-11-22T15:05:21Z","email":"hyatt@example.com","id":3,"name":"Hyattt","password":"xHiFow8","updated_at":"2011-11-23T16:28:23Z"}},{"client":{"api_key":"mQguvRtPsatjYbDB2j9c","created_at":"2011-11-23T17:07:59Z","email":"werwer@rtwetr.com","id":4,"name":"wew","password":"T4snwtW","updated_at":"2011-11-23T17:07:59Z"}},{"client":{"api_key":"uaKL3TQIlI09lUr1Gkap","created_at":"2011-11-23T17:38:33Z","email":"sadfsadfwe@t.com","id":5,"name":"wew111","password":"tf6smXv","updated_at":"2011-11-23T17:38:33Z"}},{"client":{"api_key":"OutTRbifZWqaSpOLMYbX","created_at":"2011-11-23T17:40:11Z","email":"fddd@ee2.com","id":6,"name":"wew12","password":"dyOKg36","updated_at":"2011-11-23T17:40:11Z"}},{"client":{"api_key":"ypnI6D9RVNmnFDlHb8a3","created_at":"2011-11-23T18:25:24Z","email":"g@fff.com","id":7,"name":"Hyatt","password":"U9KxRdY","updated_at":"2011-11-23T18:25:24Z"}},{"client":{"api_key":"qBKpo64gkpszsL4xxCHC","created_at":"2011-11-23T18:25:49Z","email":"t@t.com","id":8,"name":"Hayatt","password":"QzS5463456","updated_at":"2011-11-24T12:00:35Z"}},{"client":{"api_key":"sybI0zW71RED54eVwy85","created_at":"2011-11-23T18:26:45Z","email":"e2718281828@ya.ru","id":9,"name":"Hyatt2","password":"1!ojBf7","updated_at":"2011-11-23T18:26:45Z"}},{"client":{"api_key":"bcyYzeTgQ61uF4VoGFE8","created_at":"2011-11-23T18:46:06Z","email":"err@eee.com","id":10,"name":"err","password":"6WHgd$4","updated_at":"2011-11-23T18:46:06Z"}},{"client":{"api_key":"4BZfYi3FoPHOOatUQJrZ","created_at":"2011-11-24T12:03:31Z","email":"testr@example.com","id":11,"name":"testr","password":"vAprbwZ","updated_at":"2011-11-24T12:03:31Z"}}]'

    @modified_list_json = '[{"client":{"api_key":"QH86LEt42hjsDASLgzz9","created_at":"2011-11-21T16:18:14Z","email":"testee@example.com","id":1,"name":"Cogniance","password":"!z$RdqW","updated_at":"2011-11-22T14:11:58Z"}},{"client":{"api_key":"ms6LOrgcgLTO6oBUaUTI","created_at":"2011-11-22T15:05:21Z","email":"hyatt@example.com","id":3,"name":"Hyattt","password":"xHiFow8","updated_at":"2011-11-23T16:28:23Z"}},{"client":{"api_key":"mQguvRtPsatjYbDB2j9c","created_at":"2011-11-23T17:07:59Z","email":"cogniance@rtwetr.com","id":4,"name":"wew","password":"T4snwtW","updated_at":"2011-11-23T17:07:59Z"}},{"client":{"api_key":"uaKL3TQIlI09lUr1Gkap","created_at":"2011-11-23T17:38:33Z","email":"sadfsadfwe@t.com","id":5,"name":"wew111","password":"tf6smXv","updated_at":"2011-11-23T17:38:33Z"}},{"client":{"api_key":"OutTRbifZWqaSpOLMYbX","created_at":"2011-11-23T17:40:11Z","email":"fddd@ee2.com","id":6,"name":"wew12","password":"dyOKg36","updated_at":"2011-11-23T17:40:11Z"}},{"client":{"api_key":"ypnI6D9RVNmnFDlHb8a3","created_at":"2011-11-23T18:25:24Z","email":"g@fff.com","id":7,"name":"Hyatt","password":"U9KxRdY","updated_at":"2011-11-23T18:25:24Z"}},{"client":{"api_key":"qBKpo64gkpszsL4xxCHC","created_at":"2011-11-23T18:25:49Z","email":"t@t.com","id":8,"name":"Hayatt","password":"QzS5463456","updated_at":"2011-11-24T12:00:35Z"}},{"client":{"api_key":"sybI0zW71RED54eVwy85","created_at":"2011-11-23T18:26:45Z","email":"e2718281828@ya.ru","id":9,"name":"Hyatt2","password":"1!ojBf7","updated_at":"2011-11-23T18:26:45Z"}},{"client":{"api_key":"bcyYzeTgQ61uF4VoGFE8","created_at":"2011-11-23T18:46:06Z","email":"err@eee.com","id":10,"name":"err","password":"6WHgd$4","updated_at":"2011-11-23T18:46:06Z"}},{"client":{"api_key":"4BZfYi3FoPHOOatUQJrZ","created_at":"2011-11-24T12:03:31Z","email":"testr@example.com","id":11,"name":"testr","password":"vAprbwZ","updated_at":"2011-11-24T12:03:31Z"}}, {"client":{"api_key":"miZTyI7fOPHAAoiuqjRr","created_at":"2011-11-24T10:22:31Z","email":"dima@example.com","id":13,"name":"dima","password":"werZwbr","updated_at":"2011-11-24T13:13:31Z"}}]'
  end

  it "should parse clients list received from market api" do
    ClientsSync.stub(:responce).and_return(@list_json)
    ClientsSync.parse_clients_list
    ClientsSync.clients_list.size.should == 10
  end

  it "should create clients in the clients table" do
    ClientsSync.stub(:responce).and_return(@list_json)
    ClientsSync.parse_clients_list

    Client.count.should == 0
    users_count_before_sync = User.count

    ClientsSync.sync

    Client.count.should == 10
    User.all.each{|u| u.role.should == 'client'}
    User.count.should == users_count_before_sync + 10
    Client.all.each{|client| client.user.should be }
  end

  it "should update client's and user's info when something was changed in market" do
    ClientsSync.stub(:responce).and_return(@list_json)
    ClientsSync.parse_clients_list
    ClientsSync.sync

    clients_count_after_sync = Client.count
    users_count_after_sync = User.count

    ClientsSync.stub(:responce).and_return(@modified_list_json)
    ClientsSync.parse_clients_list
    ClientsSync.sync

    Client.count.should == clients_count_after_sync + 1
    User.count.should == users_count_after_sync + 1

    Client.find_by_api_key('mQguvRtPsatjYbDB2j9c').email.should == 'cogniance@rtwetr.com'
    Client.find_by_api_key('QH86LEt42hjsDASLgzz9').name.should == 'Cogniance'
  end
end
