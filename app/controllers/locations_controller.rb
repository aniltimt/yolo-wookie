class LocationsController < ResourceController::Base
  has_scope :tagged_with
  has_scope :in_city
  has_scope :in_country

  cache_sweeper :location_sweeper, :only => [ :update, :destroy ]

  def index
    super if !request.xhr? # to set current_scopes var from params (used in menu/_locations.html.haml)
    #@locations = current_user.locations
    respond_to do |format|
      format.html {}
      format.js {
        render :layout => 'none', :template => 'locations/list'
      }
    end
  end
=begin
  def new
    @locations = current_user.locations
    @location = Location.new
  end

  def show
    @locations = current_user.locations
    @location = current_user.locations.find params[:id]
  end

  def edit
    @locations = current_user.locations
    @location = current_user.locations.find params[:id]
  end
=end
  def create
    if params["location"]
      address = []
      address << params["location"]["street"] if !params["location"]["street"].blank?
      address << params["location"]["building"] if !params["location"]["building"].blank?
      params["location"]["address"] = address.join(', ')
      params["location"]["user_id"] = current_user.id
      params["location"]["medium_ids"] = params["location"]["medium_ids"].reject{|medium_id| medium_id.blank?}.uniq
    end

    super
  end

  def update
    if params["location"]
      address = []
      address << params["location"]["street"] if !params["location"]["street"].blank?
      address << params["location"]["building"] if !params["location"]["building"].blank?
      params["location"]["address"] = address.join(', ')

      params["location"]["medium_ids"] = params["location"]["medium_ids"].reject{|medium_id| medium_id.blank?}.uniq
    end

    super
  end

  def search
    @loi = if params[:term].blank?
      Location.in_city(params[:in_city]).in_country(params[:in_country])
    else
      by_tags = Location.in_city(params[:in_city]).in_country(params[:in_country]).tagged_with(params[:term].split(',').map{|n| n.strip}, :any => :true)
      #names = params[:term].split(',').map{|n| "'#{n.strip}'"}.join(',')
      by_names = Location.in_city(params[:in_city]).in_country(params[:in_country]).find(:all, :conditions => ["name LIKE ?", "%#{params[:term]}%"])
      by_tags + by_names
    end

    respond_to do |format|
      format.json {
        render :json => @loi.uniq.as_json
      }
    end
  end

  def gmap_reverse_geocode
    google_response = gmap_request_reverse_geocode(params[:lat], params[:lon])
    
    city, country = gmap_reverse_geocode_country_city_aliases(google_response)
    
    geoinfo = {}
    geoinfo.merge!({:city => city}) if city
    geoinfo.merge!({:country => country}) if country
    render :text => geoinfo.to_json, :layout => false
  end

  def get_coordinates_for_loi
    loi = []
    params[:ids].each do |id|
      loi << Location.find(id)
    end
    render :json => loi.collect{|l| [l.lat, l.lng]}.to_json, :layout => false
  end

  protected

  def begin_of_association_chain
    current_user
  end

  def gmap_request_reverse_geocode(lat,lon)
    require 'net/http'    
    response = Net::HTTP.get_response(URI.parse("http://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat.to_f},#{lon.to_f}&sensor=false&language=en")).body
    #Rails.logger.warn "response - #{response.inspect}"
    response
  end
    
  def gmap_reverse_geocode_country_city_aliases(google_response)
    response_parsed = JSON.parse(google_response.to_s)
      
    city = nil
    if !response_parsed['results'].empty?
      response_parsed['results'].each do |result|
        if !result['address_components'].blank? && (result['address_components'][0]['types'].include?("locality") || result['address_components'][0]['types'].include?("administrative_area_level_1"))

          Rails.logger.warn "result['address_components'][0] - " + result['address_components'][0].inspect
            
          city = result['address_components'][0]['long_name'].gsub("'",'')
          break if city
        end
      end
    end
      
    Rails.logger.warn 'city - ' + city.inspect
   
    country = if !response_parsed['results'].empty?
      if !response_parsed['results'].last['address_components'].blank? && response_parsed['results'][2]['address_components'].last['long_name']
        response_parsed['results'][2]['address_components'].last['long_name'].gsub("'",'')
      end
    end
      
    Rails.logger.warn 'country - ' + country.inspect
      
    [city, country]
  end
end
