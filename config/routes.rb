ActionController::Routing::Routes.draw do |map|
  map.devise_for :users, :path_names => { :sign_out => '/logout' }

  map.resources :users, :only => [:edit, :update]

  map.connect '/find_categories_by_name', :controller => 'application', :action => 'find_categories_by_name'

  %w(video picture audio text_page).each do |media_type|
    map.send("#{media_type}_media", "/media/#{media_type.pluralize}", :controller => 'media', :action => 'index', media_type.pluralize.to_sym => 'true')
    map.send("#{media_type}_media_json", "/media/#{media_type.pluralize}.json", :controller => 'media', :action => 'index', media_type.pluralize.to_sym => 'true', :format => :json)
  end

  map.connect "/media/tagged_with", :controller => 'media', :action => "tagged_with"
  map.connect "/media/search/:name", :controller => 'media', :action => "search", :name => /.*/
  map.connect "/media/upload/:fileapi", :controller => 'media', :action => "upload"

  map.resources :media

  map.video_media '/media/videos', :controller => 'media', :action => 'index', :videos => 'true'

  map.gmap_reverse_geocode '/locations/gmap_reverse_geocode', :controller => "locations", :action => "gmap_reverse_geocode"
  map.connect '/locations/get_coordinates_for_loi', :controller => "locations", :action => "get_coordinates_for_loi"
  map.connect '/locations/search', :controller => "locations", :action => "search"

  map.resources :locations

  map.connect '/tours/check_city_bbox', :controller => "tours", :action => "check_city_bbox"
  map.connect '/tours/get_coordinates_for_tours', :controller => "tours", :action => "get_coordinates_for_tours"
  map.resources :ubertours

  map.resources :tours, :member => {:schedule_build => :post, :get_build_status => :get} #do |tour|
    #tour.resources :locations, :controller => "TourLocations", :member => { :reorder => :put, :move_up => :put, :move_down => :put}
  #end

  map.connect '/packages', :controller => "packages", :action => :index

  map.namespace 'market' do |market|
    market.country_city '/places/:country/:city.xml', :controller => :places, :action => :show
    market.country '/places/:country.xml', :controller => :places, :action => :show
    market.places '/places.xml', :controller => :places, :action => :index
    market.resources :tours, :member => { :map => :get, :media => :get}
  end

  map.root :controller => 'tours', :action => 'index'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
