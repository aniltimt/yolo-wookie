require 'cloudmade/exceptions'

class TourBuilderJob

  attr_reader :tour

  @queue = '*'

  include AWS::S3

  # Entry point for delayed_job execution
  def self.perform(tour_id)
    @tour = Tour.find(tour_id)

    if @tour.is_ubertour
      # shared routing
      log("Calculating ubertour route...")
      ur = UbertourRouting.new(@tour.id)
      ubertour_routing_xml = ur.calculate
      overall_ubertour_bbox = @tour.overall_ubertour_bbox(ur.bbox)
      puts 'overall_ubertour_bbox - ' + overall_ubertour_bbox.inspect
      log("Calculating ubertour route...Done")

      log("Creating ubertour package for iPhone 3")
      # create package for iphone3
      package = TourPackage.new(:tour => @tour, :tour_name => @tour.name, :country => @tour.country, :city => @tour.city, :platform_id => PLATFORMS::IPHONE3, :south => @tour.bbox.se.lat, :east => @tour.bbox.se.lng, :north => @tour.bbox.nw.lat, :west => @tour.bbox.nw.lng)
      tileset_for_overall_city = package.add_overall_tour_map(overall_ubertour_bbox, :platform_id => PLATFORMS::IPHONE3, :tour_id => @tour.id)
      ubertour_xml = @tour.generate_ubertour_xml(PLATFORMS::IPHONE3)
      package.add_file(package.tour_xml_name, ubertour_xml)
      package.add_file(package.ubertour_routing_xml_name, ubertour_routing_xml)
      package.save!

      log("Creating ubertour package for iPhone 4")
      # create package for iphone4 with build_id from iphone3 package
      iphone4_package = TourPackage.new(:tour => @tour, :tour_name => @tour.name, :country => @tour.country, :city => @tour.city, :platform_id => PLATFORMS::IPHONE4, :south => @tour.bbox.se.lat, :east => @tour.bbox.se.lng, :north => @tour.bbox.nw.lat, :west => @tour.bbox.nw.lng)
      tileset_for_overall_city = iphone4_package.add_overall_tour_map(overall_ubertour_bbox, :platform_id => PLATFORMS::IPHONE4, :tour_id => @tour.id)
      ubertour_xml = @tour.generate_ubertour_xml(PLATFORMS::IPHONE4)
      iphone4_package.add_file(iphone4_package.tour_xml_name, ubertour_xml)
      iphone4_package.add_file(iphone4_package.ubertour_routing_xml_name, ubertour_routing_xml)
      iphone4_package.save_with_build_id = package.id
      iphone4_package.save!
    else
      if :cloudmade == ROUTING_METHOD
        log("Starting routing server")
        start_routing_server_if_not_running

        while routing_server_state != 'running'
          @routing_server_was_down = true
          sleep(20) # wait for 20 seconds before server will be responding
          log('waiting routing server for 20 sec which is in state - ' + routing_server_state.inspect)
        end

        if @routing_server_was_down
          log("Waiting 10 minutes before all server's deamons and services will be up and running")
          sleep(600)
          log("Associating elastic ip with routing server instance")
          associate_elastic_ip
        end

        log("Creating on S3 lock file for prerouting server")
          locked_time = Time.current.to_i
          create_s3_file_lock_for_prerouting_server(locked_time)

        log("Requesting routes")
          request = Cloudmade::Request.new(@tour.bbox.enlarge!(:padding => BBOX_PADDING), @tour.location_coords)
          route_graph = request.run

        log("Checking for unused points in prerouting")
          route_graph.check_for_unused_points_in_prerouting

      elsif :osm == ROUTING_METHOD
        log("Requesting routing from OSM")
          enlarged_bbox = @tour.bbox.enlarge!(:padding => BBOX_PADDING)
          receiver = ::OsmReceiver.new(:north => enlarged_bbox.nw.lat, :west => enlarged_bbox.nw.lng, :south => enlarged_bbox.se.lat, :east => enlarged_bbox.se.lng)
          receiver.get_osm_xml
          #receiver.files = ['osm_1_1.xml', 'osm_1_2.xml', 'osm_1_3.xml', 'osm_1_4.xml']
          receiver.merge_files
        log("Generating binary with OSM routing graph")
          receiver.generate_bin
      end

      # LOADING LOW-RES TILES 
      log "Loading low-res tiles"
        tile_loader = TileLoader.new(CLOUDMADE_API_KEY, :tour_id => @tour.id)
        tiles = tile_loader.get_area_levels(:cloudmade == ROUTING_METHOD ? route_graph.bbox : @tour.bbox.enlarge!(:padding => BBOX_PADDING))

      log "Constructing tour package with low-res tiles"
        @builder = PackageBuilder.new(@tour, :platform_id => PLATFORMS::IPHONE3)
        @builder.add_graph_data(route_graph.segments) if :cloudmade == ROUTING_METHOD
        @builder.set_prerouting(route_graph.routes) if :cloudmade == ROUTING_METHOD
        @builder.add_osm_routing(receiver.tmp_routing_bin) if :osm == ROUTING_METHOD
        tiles.each{ |ts| @builder.add_tileset(ts)}

      log "Building package with low-res tiles"
        tour_package = @builder.build!
        # pobs bundle should be builded only once (it's independent from PLATFORM_IDs)
        tour_package.add_pobs_to_tour
        tour_package.save!

      # LOADING HI-RES TILES 
      log "Loading hi-res tiles"
        hires_tile_loader = TileLoader.new(CLOUDMADE_API_KEY, :tour_id => @tour.id, :load_hires_tiles => true)
        hires_tiles = hires_tile_loader.get_area_levels(:cloudmade == ROUTING_METHOD ? route_graph.bbox : @tour.bbox.enlarge!(:padding => BBOX_PADDING))

      log "Constructing tour package with hi-res tiles"
        @builder_for_iphone4 = PackageBuilder.new(@tour, :platform_id => PLATFORMS::IPHONE4)
        @builder_for_iphone4.add_graph_data(route_graph.segments) if :cloudmade == ROUTING_METHOD
        @builder_for_iphone4.set_prerouting(route_graph.routes) if :cloudmade == ROUTING_METHOD
        @builder_for_iphone4.add_osm_routing(receiver.tmp_routing_bin) if :osm == ROUTING_METHOD
        hires_tiles.each{ |ts| @builder_for_iphone4.add_tileset(ts)}

      log "Building package with hi-res tiles"
        iphone4_tour_package = @builder_for_iphone4.build!
        iphone4_tour_package.save_with_build_id = tour_package.id
        iphone4_tour_package.save!
    end

    @tour.publish!

    log "Build complete"
  rescue => e
    message = "Build failed: %s"
    reason = case e 
      when Cloudmade::MalformedResponse: "Malformed geodata provider response"
      when Cloudmade::TourTooBig: "Tour area is too big"
      when Cloudmade::ServiceUnavailable: "Service is unavaliable, try later (#{e.message})"
      when Cloudmade::RoutesUnavailable: "Route between LOIs or tours #{@tour.is_ubertour ? '(intertour route type: by '+@tour.ubertour_route_type+')' : ''} couldn't be calculated"
      when Cloudmade::TilesUnavailable: "Tile server does not respond in 60 minutes"
      when Cloudmade::PoiAbsentInPrerouting: e.message
      else "Unknown error (#{e.message})"
    end
    Rails.logger.warn(message % reason)
    Rails.logger.warn 'backtrace - ' + e.backtrace.inspect
    @tour.build_failed! if @tour

    log(message % reason)
    delete_s3_lock_for_prerouting_server(locked_time)
    raise
  ensure
    # if server is running and no other Ec2StopJobs were enqueued
    # which might be the case if an exception had be thrown before in this action (like Cloudmade::ServiceUnavailable)

    if routing_server_state == 'running' #&& !Resque.all.any?{|dj| dj.handler =~ /Ec2StopJob/}
      #Delayed::Job.enqueue(Ec2StopJob.new, 0, 10.hours.from_now)
      Resque.enqueue_at(10.hours.from_now, Ec2StopJob)
    end

    delete_s3_lock_for_prerouting_server(locked_time)
  end

  def self.on_permanent_failure
    @tour.build_failed! if @tour
  end
  
  protected

  def self.log(message)
    Rails.logger.debug("Building tour #{@tour.id} - #{message}")
    @tour.update_attribute(:build_message, message)
  end

  def self.routing_server_state
    @ec2 ||= AWS::EC2::Base.new(:access_key_id => ROUTING_SERVER_ACCESS_KEY, :secret_access_key => ROUTING_SERVER_SECRET)
    state = @ec2.describe_instances(:instance_id => [ROUTING_SERVER_INSTANCE_ID])
    state["reservationSet"]['item'][0]["instancesSet"]['item'][0]["instanceState"]['name']
  end

  def self.start_routing_server_if_not_running
    @ec2 ||= AWS::EC2::Base.new(:access_key_id => ROUTING_SERVER_ACCESS_KEY, :secret_access_key => ROUTING_SERVER_SECRET)
    state = @ec2.describe_instances(:instance_id => [ROUTING_SERVER_INSTANCE_ID])
    @ec2_state = state["reservationSet"]['item'][0]["instancesSet"]['item'][0]["instanceState"]['name']
    if @ec2_state == "stopped"
      @ec2.start_instances :instance_id => [ROUTING_SERVER_INSTANCE_ID]
    end
  end

  def self.associate_elastic_ip
    @ec2.associate_address(:instance_id => ROUTING_SERVER_INSTANCE_ID, :public_ip => ROUTING_SERVER_EIP)
  end

  def self.create_s3_file_lock_for_prerouting_server(timestamp)
    Base.establish_connection!(:access_key_id => S3_ACCESS_KEY, :secret_access_key => S3_SECRET)

    if !Service.buckets.collect{|bucket| bucket.name}.include?('tour_builds_synchronization')
      Rails.logger.warn "creating 'tour_builds_synchronization' bucket"
      Bucket.create('tour_builds_synchronization')
    end

    if S3Object.exists?('tour_building', 'tour_builds_synchronization')
      building_tour_timestamp = S3Object.value('tour_building', 'tour_builds_synchronization')

      # if currently building tour is newer then in s3 lock file shift timestamp in it (to ensure ec2 
      if timestamp > building_tour_timestamp.to_i
        S3Object.store('tour_building', timestamp.to_s, 'tour_builds_synchronization')
      end
    else
      S3Object.store('tour_building', timestamp.to_s, 'tour_builds_synchronization')
    end
  end

  def self.delete_s3_lock_for_prerouting_server(timestamp)
    Base.establish_connection!(:access_key_id => S3_ACCESS_KEY, :secret_access_key => S3_SECRET)
    if Service.buckets.collect{|bucket| bucket.name}.include?('tour_builds_synchronization')
      if S3Object.exists?('tour_building', 'tour_builds_synchronization')
        building_tour_timestamp = S3Object.value('tour_building', 'tour_builds_synchronization')
        S3Object.delete('tour_building', 'tour_builds_synchronization') if building_tour_timestamp.to_i == timestamp.to_i
      end
    end
  end
end
