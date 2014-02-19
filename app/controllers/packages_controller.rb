class PackagesController < ApplicationController
  layout nil
  def index
    @packages = Tour.all.map{ |t| t.builds.first}
  end
end
