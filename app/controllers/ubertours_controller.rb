class UbertoursController < ResourceController::Base

  # we include here TourHelper to use #country_from_iso_code
  include ToursHelper

  has_scope :in_city, :in_country
  has_scope :draft, :building, :published, :failed, :edited

  def show
    @ubertours = current_user.ubertours
    begin
      @ubertour = current_user.ubertours.find params[:id]
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "You don't have permission to see this ubertour"
      redirect_to :action => 'index'
    end
  end

  def update
    @ubertour = Tour.find params[:id]
    @added_tours_list = params[:added_tours_list].to_s.split(',').map{|t_id| Tour.find(t_id.strip)}.compact

    @country = params[:tour][:country]
    @city = params[:tour][:city]

    tour_ubertours = TourUbertour.find_all_by_ubertour_id(@ubertour.id)
    tour_ubertours.each{|tu| tu.destroy}

    if @ubertour.update_attributes(params[:tour])
      @added_tours_list.each_with_index do |tour, index|
        TourUbertour.create! :tour_id => tour.id, :ubertour_id => @ubertour.id, :position => (index + 1)
      end
      flash[:notice] = "You successfully edited an Übertour"
      redirect_to :controller => "ubertours", :action => "show", :id => @ubertour.id
    else
      @ubertours = current_user.ubertours
      render :action => "new"
    end
  end

  def edit
    @ubertours = current_user.ubertours

    begin
      @ubertour = current_user.ubertours.find params[:id]
      @added_tours_list = @ubertour.children
      @country = @ubertour.country
      @city = @ubertour.city
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "You don't have permission to edit this ubertour"
      redirect_to :action => 'index'
    end
  end

  def new
    @ubertours = current_user.ubertours
    @ubertour = Tour.new
  end

  def create
    @ubertour = Tour.new params[:tour]
    @ubertour.is_ubertour = true
    @ubertour.user_id = current_user.id
    @added_tours_list = params[:added_tours_list].to_s.split(',').map{|t_id| Tour.find(t_id.strip)}.compact

    @country = params[:tour][:country]
    @city = params[:tour][:city]

    if @ubertour.save
      @added_tours_list.each_with_index do |tour, index|
        TourUbertour.create! :tour_id => tour.id, :ubertour_id => @ubertour.id, :position => (index + 1)
      end
      flash[:notice] = "You successfully created new ubertour"
      redirect_to :controller => "ubertours", :action => "show", :id => @ubertour.id
    else
      @ubertours = current_user.ubertours
      render :action => "new"
    end
  end

  def destroy
    destroy! do |format|
      format.html do
        redirect_to ({:action => 'index'}.merge(params[:draft] ? {:draft => true} : {}))
      end
    end
  end

  def schedule_build
    ubertour = Tour.find(params[:id])
    ubertour.build_ubertour!
    redirect_to :controller => "ubertours", :action => "show", :id => ubertour.id
  end

  def get_build_status
    render :text => Tour.find(params[:id]).build_message, :layout => false
  end

  protected
    def begin_of_association_chain
      current_user
    end
end
