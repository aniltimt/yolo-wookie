require 'rubygems'
require 'httparty'
require 'nokogiri'
require 'thread'

class OsmReceiver
  include HTTParty

  base_uri 'www.openstreetmap.org'
  default_timeout 240

  def files=(files)
    @@files = files
  end

  attr_accessor :tmp_routing_bin

  def initialize(options)
    @north    = options[:north]
    @west     = options[:west]
    @south    = options[:south]
    @east     = options[:east]
    @kvadrant = options[:kvadrant] || "0"
    @level    = options[:level] || 0
    @@files   ||= []
    @tmp_routing_bin = Tempfile.new('osm_routing')
    @retry_count = 0
    @semaphore = Mutex.new
  end

  def log(str)
    if !Rails.env.production?
      puts str
    else
      Rails.logger.warn str
    end
  end

  def get_osm_xml
    log 'getting xml from OSM'

    begin
      while @semaphore.locked?
        log 'OSM semaphore locked'
        sleep(10)
      end
      @semaphore.lock
      resp = self.class.get("/api/0.6/map", :query => {:bbox => "#{@west},#{@south},#{@east},#{@north}"}, :headers => {"User-Agent" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; en-US) AppleWebKit/533.4 (KHTML, like Gecko) Chrome/5.0.375.125 Safari/533.4"})
    rescue Timeout::Error => e
      @retry_count += 1
      if @retry_count < 10
        log 'Retrying getting xml from OSM'
        retry
      else
        raise Cloudmade::ServiceUnavailable
      end
    ensure
      @semaphore.unlock
    end

    if resp.response.class == Net::HTTPBadRequest && resp.header["error"]=~ /either request a smaller area, or use planet\.osm/i
      log 'bad request: splitting into 4'
      # split the area in 4 chunks
      delta_lng = @east - @west
      delta_lat = @north - @south

      # 2 north boxes
      bbox1_xml = OsmReceiver.new(:north => @north, :west => @west, :south => (@south + (delta_lat/2)), :east => (@west + (delta_lng/ 2)), :kvadrant => "#{@kvadrant}_1", :level => (@level+1)).get_osm_xml

      bbox2_xml = OsmReceiver.new(:north => @north, :west => (@west + (delta_lng/ 2)), :south => (@south + (delta_lat/2)), :east => @east, :kvadrant => "#{@kvadrant}_2", :level => (@level+1) ).get_osm_xml

      # 2 south boxes
      bbox3_xml = OsmReceiver.new(:north => (@south + (delta_lat/2)), :west => @west, :south => @south, :east => (@west + (delta_lng/ 2)), :kvadrant => "#{@kvadrant}_3", :level => (@level+1) ).get_osm_xml

      bbox4_xml = OsmReceiver.new(:north => (@south + (delta_lat/2)), :west => (@west + (delta_lng/2)), :south => @south, :east => @east, :kvadrant => "#{@kvadrant}_4", :level => (@level+1)).get_osm_xml
    elsif resp.response.class == Net::HTTPOK  # save output to file
      #tmpfile = Tempfile.new("osm_#{@level}_#{@kvadrant}.xml")
      tmpfile = Tempfile.new("osm_#{@kvadrant}.xml")
      @@files.push(tmpfile)
      log 'inserting into @@files - ' + @@files.inspect
      File.open(tmpfile.path, 'w').write(resp.body)
      tmpfile.flush
    elsif resp.response.class == Net::HTTPServerError
      log 'Net::HTTPServerError: rerequesting'
      OsmReceiver.new(:north => @north, :west => @west, :south => @south, :east => @east, :kvadrant => @kvadrant, :level => @level).get_osm_xml
    else
      log 'resp.response.class - ' + resp.response.class.inspect
    end
  end

  def merge_files
    nodes = []
    ways  = []
    log '@@files - ' + @@files.inspect
    @@files.each do |file|
      doc = Nokogiri::XML::Document.parse(file.read)
      nodes += doc.xpath('//osm/node')
      ways  += doc.xpath('//osm/way')
    end
    log 'nodes.count - ' + nodes.count.to_s
    log 'ways.count - ' + ways.count.to_s
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.osm({:version => "0.6", :generator => "CGImap 0.0.2"}) do
        nodes.each do |node|
          xml << node.to_xml
        end
        ways.each do |way|
          xml << way.to_xml
        end
      end
    end
    @tmpfile = Tempfile.new('final_osm')
    @tmpfile.write(builder.to_xml)
    log 'wrote final osm xml to ' + @tmpfile.path.inspect
    @tmpfile.close
  end

  def generate_bin
    #exec "java -Xmx15000m -cp routing.jar com.cloudmade.routing.OsmParser -m construct -f ./final_osm.xml -n 1000000 -u 2000 -r 0.0001 -s true -o routing.bin"
    system "java -Xmx15000m -cp #{File.join(File.dirname(File.expand_path(__FILE__)), 'routing.jar')} com.digitalfootsteps.importtool.Importer -m construct -f #{@tmpfile.path} -n 1000000 -u 2000 -r 0.0001 -s true -o #{@tmp_routing_bin.path}"
    log 'java file done his work'
    @tmpfile.unlink
    @@files.each{|file| file.unlink}
  end
end
