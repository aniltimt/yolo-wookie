class Market::ToursController < ApplicationController

  before_filter :load_build, :only => [:show, :map, :media]

  def show
    respond_to do |format|
      format.xml {render :xml => File.read(@build.tour_xml_path) }
    end
  end

  def map
    respond_to do |format|
      format.all { send_file @build.map_pack_path }
    end
  end

  def media
    respond_to do |format|
      format.all { send_file @build.tour_pack_path }
    end
  end

  private

  def load_build
    @tour = Tour.find(params[:id])
    @build = @tour.builds.first(:order => "created_at desc")
  end

  def build_root
    @build.build_root
  end

  def content_root
    @build.content_root
  end
end
