class ToursController < ResourceController::Base

  # we include here TourHelper to use #country_from_iso_code
  include ToursHelper

  has_scope :by_category
  has_scope :draft, :building, :published, :failed, :edited
  has_scope :in_city, :in_country

  cache_sweeper :tour_sweeper, :only => [ :update, :destroy ]

  before_filter :get_pob_categories, :only => [:new, :show, :edit, :show, :update, :create]

  def show
    begin
      @tour = current_user.tours.find params[:id]
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "You don't have permission to see this tour"
      redirect_to :action => 'index'
    end

    @selected_pob_categories = begin
      @tour.pob_categories_ids.to_s.split(',').map{|p| p.to_i}.inject([]) do |sum, id|
        sum << @pob_categories[:list][id]
      end.join(', ')
    rescue => e # if market is unavailable and no @pob_categories are builded
      ""
    end

    super
  end

  def update
    params[:tour][:pob_categories_ids] = params[:tour][:pob_categories_ids].to_a.join(',')
    
    params[:tour][:tour_locations_attributes] = []
    lois = []
    tour = current_user.tours.find params[:id]
    existing_tour_locations_ids = tour.tour_locations.map{|tl| tl.location.id}
    tour_locations_hash = tour.tour_locations.inject({}){|sum, tl| sum.merge!({tl.location.id => tl.id}) }

    if ! params[:deleted_items].blank?
      @deleted_items = params[:deleted_items]

      params[:deleted_items].split(',').map do |di|
        if existing_tour_locations_ids.include?(di.strip.to_i)
          lois << {:id => tour_locations_hash[di.strip.to_i], :_destroy => true}
        end
      end
    end

    params[:location].each_with_index do |token, i|
      # _destroy, id, position, location_id
      id, location_id = token.split('_')
      lois << {:id => (id.blank? || id=="0" ? '' : id), :location_id => location_id, :position => i, :_destroy => false}
    end
    
    lois.each{ |h| params[:tour][:tour_locations_attributes] << h }

    @tour_locations = if tour.valid? && params[:location].blank?
      tour.tour_locations.collect{|tl| {:id => tl.id, :location_id => tl.location_id, :location_comment => tl.location.comment, :location_name => tl.location.name} }
    else
      params[:location].collect do |l| 
        if l.split('_')[0] == '0' || l.split('_')[0].blank?
          loi = Location.find l.split('_')[1]
          {:id => '0', :location_id => l.split('_')[1], :location_comment => loi.comment, :location_name => loi.name}
        else
          tl = TourLocation.find( l.split('_')[0] )
          {:id => tl.id, :location_id => tl.location_id, :location_comment => tl.location.comment, :location_name => tl.location.name}
        end
      end.uniq.flatten
    end

    super
  end

  def edit
    @tour_locations = Tour.find(params[:id]).tour_locations.collect{|tl| {:id => tl.id, :location_id => tl.location_id, :location_comment => tl.location.comment, :location_name => tl.location.name} }
    @tours = current_user.tours.regular_tours

    begin
      @tour = current_user.tours.find params[:id]
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "You don't have permission to edit this tour"
      redirect_to :action => 'index'
    end
  end

  def new
    @tour_locations = []
    @tours = current_user.tours.regular_tours
    @tour = Tour.new
  end

  def create 
    params[:tour][:pob_categories_ids] = params[:tour][:pob_categories_ids].to_a.join(',')  
    params[:tour][:tour_locations_attributes] = []
    params[:location].each_with_index do |token, i|
      # _destroy, id, position, location_id
      id, location_id = token.split('_')
      h = {:id => (id.blank? || id=="0" ? '' : id), :location_id => location_id, :position => i, :_destroy => false}
      params[:tour][:tour_locations_attributes] << h
    end

    @tour_locations = params[:location].collect do |l| 
      if l.split('_')[0] == '0' || l.split('_')[0].blank?
        loi = Location.find l.split('_')[1]
        {:id => '0', :location_id => l.split('_')[1], :location_comment => loi.comment, :location_name => loi.name}
      else
        tl = TourLocation.find( l.split('_')[0] )
        {:id => tl.id, :location_id => tl.location_id, :location_comment => tl.location.comment, :location_name => tl.location.name}
      end
    end.uniq.flatten
    params[:tour][:user_id] = current_user.id
    super
  end

  def destroy
    destroy! do |format|
      format.html do
        redirect_to params[:draft] ? tours_url(:draft => true) : tours_url
      end
    end
  end

  def schedule_build
    tour = Tour.find(params[:id])
    tour.build!
    redirect_to (tour.is_ubertour? ? {:controller => "ubertours", :action => "show", :id => tour.id} : tour)
  end

  def get_build_status
    render :text => Tour.find(params[:id]).build_message, :layout => false
  end

  def check_city_bbox
    result = false
    error_message = ''
    country_name = params[:country]
    city_name = params[:city]
    city_bbox = []

    if !country_name.blank?
      city_bbox = Tour.get_city_bbox(country_from_iso_code(country_name), city_name)
      if((city_bbox.nw.lat - city_bbox.se.lat).abs > 0.5 && (city_bbox.nw.lng - city_bbox.se.lng).abs > 0.5)
        error_message = "Either the city '#{city_name}' is not situated in '#{country_from_iso_code(country_name)}' or there is no such city at all."
      else
        result = true
      end
    else
      error_message = 'Country is not selected!'
    end

    tours = if params[:is_ubertour]
      Tour.by_user(current_user).regular_tours.in_country(country_name).in_city(city_name).published.all.map{|t| {:name => t.name, :id => t.id} }
    else
      []
    end

    render :json => {:bbox => city_bbox, :result => result, :error_message => error_message, :tours => tours}.to_json, :layout => false
  end

  def get_coordinates_for_tours
    tours = []

    if params[:ids].blank?
      render(:json => [].to_json, :layout => false) && return
    end

    params[:ids].each do |id|
      tours << Tour.find(id)
    end
    render :json => tours.collect{|t| t.locations.collect{|l| [l.lat, l.lng]}}.to_json, :layout => false
  end


protected
  def begin_of_association_chain
    current_user
  end

  def collection
    @tours ||= end_of_association_chain.regular_tours
  end

  def cache_key
    filters = %w(published draft building edited failed)
    keys = current_scopes.keys
    if keys.length == 1
      if filters.include?(keys.first.to_s)
        return "all_" << keys.first.to_s << "_tours"
      end
    end
    if keys.empty?
      "all_tours"
    end
  end
  helper_method :cache_key

private
  def get_pob_categories
    return @pob_categories if defined?(@pob_categories)
    @pob_categories = Rails.cache.fetch "pob_categories_names" do
      require 'open-uri'
      require 'nokogiri'

      categories_tree, categories_list = Hash.new([]), {}

      xml = Nokogiri::XML.parse(open(MARKET_API_SERVER_URL + '/v1/pob_categories.xml'))
      xml.document.elements[0].elements.each do |el|
        id = el['id'].to_i
        next if id == 0
        if el['parent_id'].blank?
          categories_tree[id] = []
        else
          categories_tree[el['parent_id'].to_i] << id
        end
        categories_list[id] = el['name'] 
      end

      {:list => categories_list, :tree => categories_tree}
    end
  rescue => e
    {:list => {}, :tree => {}}
  end

end
