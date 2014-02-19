class AwsController < ResourceController::Base
  before_filter :initialize_ec2_connection#, :only => [:start_routing_server, :stop_routing_server]
  
  def index
    respond_to do |format|
      format.html { render :layout => 'ascetic', :template => "aws/index"   }
    end
  end

  def start_routing_server
    flash['notice'] = if @ec2_state == "stopped"
      @ec2.start_instances :instance_id => [ROUTING_SERVER_INSTANCE_ID]
      sleep(20)
      @ec2.associate_address(:instance_id => ROUTING_SERVER_INSTANCE_ID, :public_ip => ROUTING_SERVER_EIP)
      "Starting routing server"
    elsif @ec2_state == "stopping"
      "Routing server is stopping"
    elsif @ec2_state == 'running'
      "Routing server is running"
    end
    redirect_to :action => 'index'
  end

  def stop_routing_server
    if @ec2_state == "running"
      @ec2.stop_instances :instance_id => [ROUTING_SERVER_INSTANCE_ID]
      flash['notice'] = "Stopping routing server"
    elsif @ec2_state == 'stopping'
      flash['notice'] = "Routing server is stopping"      
    else @ec2_state == 'stopped'
      flash['notice'] = "Routing server is already stopped"
    end
    redirect_to :action => 'index'
  end

  private
    def initialize_ec2_connection
      @ec2 ||= AWS::EC2::Base.new(:access_key_id => ROUTING_SERVER_ACCESS_KEY, :secret_access_key => ROUTING_SERVER_SECRET)
      state = @ec2.describe_instances(:instance_id => [ROUTING_SERVER_INSTANCE_ID])
      @ec2_state = state["reservationSet"]['item'][0]["instancesSet"]['item'][0]["instanceState"]['name']
      @ec2_color = case @ec2_state
        when 'stopped'; "red"
        when 'pending'; "yellow"
        when 'stopping'; "yellow"
        when 'running'; "green"
      end
    end
end
