module MediaHelper
  def no_media_filter?
    %w(videos pictures audios text_pages).all? {|filter_type| params[filter_type].blank? }
  end
  
  def current_media_type
    %w(videos pictures audios text_pages).select {|filter_type| !params[filter_type].blank? }.first
  end
  
  def current_media_url
    no_media_filter? ? media_path : media_path + "/" + current_media_type
  end
end
