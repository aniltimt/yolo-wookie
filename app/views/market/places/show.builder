xml.instruct!
tours_opts = {:country => @country, :count => @tours.size}
tours_opts.merge!(:city => @city) if @city
xml.tours(tours_opts) do
  @tours.each do |tour|
    next if tour.builds.empty?
    last_build = tour.builds.sort{|m,n| m.created_at <=> n.created_at}.last

    opts = {:name => tour.name, 
      :url => last_build.tour_xml_s3_url,
      #:mapUrl => tour.map_s3_path, # don't need it now since we pack map.pack and tour.pack into one file
      #:mediaUrl => tour.media_s3_path,
      :tourUrl => last_build.tour_pack_s3_url,
			:tourID => tour.id
    }
    opts.merge!(:city => tour.city) unless @city
    xml.tour(opts)
  end
end
