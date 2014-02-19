class Market::PlacesController < ApplicationController
  def index
    @places=  Tour.published.group_by{|t| t.country}

    respond_to do |format|
      format.xml
    end
  end

  def show
    @country = params[:country]
    @city = params[:city]

    @tours = Tour.published.in_country(@country)
    @tours = @tours.in_city(@city) unless @city.blank?
    respond_to do |format|
      format.xml
    end
  end
end
