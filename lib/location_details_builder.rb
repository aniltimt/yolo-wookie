module LocationDetailsBuilder
  def build_from_params(params)
    klass = case
    when params[:attachment].blank? :
      TextDetails
    when params[:attachment].content_type =~ /video/ :
      VideoDetails
    when params[:attachment].content_type =~ /image/ :
      PictureDetails
    else
      LocationDetails
    end
    klass.new(params.merge(:location => proxy_owner))
  end
end
