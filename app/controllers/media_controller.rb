class MediaController < ResourceController::Base

  skip_before_filter :verify_authenticity_token, :authenticate_user!, :only => [:upload]

  has_scope :videos
  has_scope :pictures
  has_scope :text_pages
  has_scope :audios
  has_scope :all_media
  has_scope :in_country
  has_scope :in_city

  def index
    #@media = current_user.media
    respond_to do |format|
      format.html {
        render :layout => 'grid'
      }
      format.js {
        if params[:start] && params[:limit]
          render
        else
          render :layout => 'none', :template => 'media/list'
        end
      }
    end
  end
  
  def paged
    respond_to do |format|
      format.js { render :action => :index }
    end
  end

  def search  
    @media = if params[:name].blank?
      Medium.in_city(params[:in_city]).in_country(params[:in_country])
    else
      names = params[:name].split(',').map{|n| n.strip}
      by_tags = Medium.in_city(params[:in_city]).in_country(params[:in_country]).tagged_with(names, :any => :true)
      by_names = Medium.in_city(params[:in_city]).
        in_country(params[:in_country]).
        find(:all, :conditions => [(["name LIKE ?"] * names.count).join(' OR ')] + names.map { |name| "%#{name}%" })
      by_tags + by_names
    end

    respond_to do |format|
      format.json {
        render :json => @media.as_json
      }
    end
  end

  def upload
    #Rails.logger.warn('params[:Filedata].original_filename - ' + params[:Filedata].original_filename.inspect)
    basename = File.basename(params[:Filedata].path)
    FileUtils.mkdir_p(Rails.root.join('public', 'javascripts', 'extjs', 'awesome_uploader', 'uploads').to_s)
    uri_path = File.join('javascripts', 'extjs', 'awesome_uploader', 'uploads', params[:Filedata].original_filename.gsub(/ /,'-'))
    tmp_filename = Rails.root.join('public', uri_path)

    if params[:fileapi]
      require 'base64'
      str = Base64.decode64(File.open(params[:Filedata].path).read)
      File.open(tmp_filename, 'w') do |file|
        file.write str
      end
    else
      FileUtils.cp(params[:Filedata].path, tmp_filename)
      FileUtils.chmod 0666, tmp_filename
    end

    output = if params[:Filedata].original_filename =~ /(mov|mp4|m4v|avi|mkv|webm|ogv|mpeg|mpg|vob|divx)$/i
      `./lib/mp4info/mp4info #{tmp_filename}`
    end

    if params[:Filedata].original_filename =~ /(mov|mp4|m4v|avi|mkv|webm|ogv|mpeg|mpg|vob|divx)$/i && output =~ /iOS Not Compatible/
      render :text => {:success => "false", :error => "Not iOS compatible" }.to_json, :layout => false
    else
      medium = Medium.build_from_params(:attachment => File.open(tmp_filename))
      medium.user_id = params[:current_user_id]
      medium.valid?
    
      if medium.errors && medium.errors["attachment_fingerprint"].blank?
        render :text => {:success => "true", :path => uri_path, :type => medium.attachment_type}.to_json, :layout => false
      else
        render :text => {:success => "false", "error" => "Already exists on server"}.to_json, :layout => false
      end
    end
  end

  def create
    were_errors = false
    successfully_uploaded_media = []
    files_with_errors = []

    params[:medium] ||= []
    params[:medium].each_with_index do |medium, index|
      Rails.logger.warn 'medium - ' + medium.inspect
      medium[:tag_list] = medium[:tag_list].split(',') if !medium[:tag_list].blank?
      tmp_filepath = medium[:filepath]
      if tmp_filepath && !medium[:attachment]
        medium[:attachment] = File.open(Rails.root.join('public', tmp_filepath))
      end
      medium.delete :filepath
      position = medium.delete(:position)

      @medium = Medium.build_from_params(medium)
      @medium.user_id = current_user.id
      create! do |success, failure|
        success.html do
          successfully_uploaded_media << {:position => position, :id => @medium.id, :name => @medium.name, :type => @medium.type, :size => @medium.attachment_file_size, :filename => @medium.attachment_file_name}
          FileUtils.rm(Rails.root.join('public', tmp_filepath)) if tmp_filepath
        end
        failure.html do
          were_errors = true
          files_with_errors << {:position => position, :message => @medium.errors.full_messages.join("\n")}
        end
      end
    end

    if request.xhr?
      render(:update) do |page|
        if were_errors
          page << "updateFailed(#{successfully_uploaded_media.to_json}, #{files_with_errors.to_json})"
        end
        page << "update_locations_media_list_with_uploaded_items(#{successfully_uploaded_media.to_json}, #{were_errors})"
      end
    elsif params[:loi]
      responds_to_parent do
        render(:update) do |page|
          if were_errors
            page << "updateFailed(#{successfully_uploaded_media.to_json}, #{files_with_errors.to_json})"
          end
          page << "update_locations_media_list_with_uploaded_items(#{successfully_uploaded_media.to_json}, #{were_errors})"
        end
      end
    else
      if were_errors
        responds_to_parent do
          render(:update) do |page|
            page << "updateFailed(#{successfully_uploaded_media.to_json}, #{files_with_errors.to_json})"
          end
        end
      else
        flash[:notice] = 'Successfully uploaded file'
        responds_to_parent { redirect_to media_path }
      end
    end
  end

  def update
    params[:medium] = params[:medium].first
    params[:medium].delete(:filepath)
    params[:medium].delete(:position)

    begin
      update! do |success, failure|
        success.html do
          update_parent do |page|
            page << "store.reload();"
            page << "editMediaWindow.hide();";
          end
        end
        failure.html do
          update_parent do |page|
            page.call "updateFailed"
          end
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn "An error occured: '#{e.message}' with backtrace #{e.backtrace}"
      update_parent{|page| page.call "updateFailed" }
    end
  end
  
  def destroy
    destroy! do |format|
      format.html do
        render :update do |page|
          page << "store.reload();"
        end
      end
    end
  end
    

  def tagged_with
    # Medium.tagged_with(params[:term].to_s)
    tags = Tag.find(:all, :limit => 10, :conditions => ["name LIKE ?", "#{params[:term]}%"])
    response = tags.collect do |t|
      tagged_with = Medium.tagged_with(t.name, :limit => 1)
      next if tagged_with.blank?
      tag_image = tagged_with[0].attachment.url
      {:id => t.id, :label => "#{t.name}", :value => t.name}
    end
    render :text => response.to_json
  end

  protected

  def update_parent
    responds_to_parent do
      render :update do |page|
        yield page
      end
    end
  end
  
  def collection
    if params[:start] && params[:limit]
      page = (params[:start].to_i / params[:limit].to_i) + 1
      @media ||= end_of_association_chain.paginate(:page => page, :per_page => params[:limit].to_i)
    else
      @media ||= end_of_association_chain
    end
  end

  protected
    def begin_of_association_chain
      current_user
    end
end
