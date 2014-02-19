class Ec2StopJob
  @queue = '*'

  def self.perform
    AWS::S3::Base.establish_connection!(:access_key_id => S3_ACCESS_KEY, :secret_access_key => S3_SECRET)
    local_building_tours_count = Tour.count(:conditions => {:aasm_state => "building"})
    global_building_tours_lock = AWS::S3::S3Object.exists?('tour_building', 'tour_builds_synchronization')

    # if there are no more tours to build => stop routing server
    if local_building_tours_count == 0 && !global_building_tours_lock
      stop_routing_server
    else
      # or reschedule this task for 30 minutes later
      #Delayed::Job.enqueue(Ec2StopJob.new, 0, 30.minutes.from_now)
      Resque.enqueue_at(30.minutes.from_now, Ec2StopJob)
    end
  end

  protected
    def self.stop_routing_server
      @ec2 ||= AWS::EC2::Base.new(:access_key_id => ROUTING_SERVER_ACCESS_KEY, :secret_access_key => ROUTING_SERVER_SECRET)
      state = @ec2.describe_instances(:instance_id => [ROUTING_SERVER_INSTANCE_ID])
      ec2_state = state["reservationSet"]['item'][0]["instancesSet"]['item'][0]["instanceState"]['name']
      if ec2_state == "running"
        @ec2.stop_instances :instance_id => [ROUTING_SERVER_INSTANCE_ID]
      end
    end
end
