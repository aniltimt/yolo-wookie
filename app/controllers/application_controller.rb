class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  filter_parameter_logging :password, :password_confirmation

  def find_categories_by_name
    tags = LocationCategory.find :all, :conditions => ["name LIKE ?", "#{params[:term]}%"] 
    render :text => tags.collect{|t| t.name}.uniq.to_json, :layout => false
  end
end
