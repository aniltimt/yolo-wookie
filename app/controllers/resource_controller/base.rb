class ResourceController::Base < ::InheritedResources::Base
  respond_to :html, :xml, :json

  before_filter :authenticate_user!

  def index
    super do |format|
      format.html{ render_or_default('index') }
    end
  end

  def new
    super do |format|
      build_resource
      format.html{ render_or_default('new') }
    end
  end


  def create
    create! do |success, failure|
      failure.html{ render_or_default('new') }
    end
  end

  def edit
    super do |format|
      format.html{ render_or_default('edit') }
    end
  end

  def update
    super do |success, failure|
      failure.html{ render_or_default('edit') }
    end
  end

  protected

  def collection
    get_collection_ivar || set_collection_ivar(end_of_association_chain.all)
  end

  def render_or_default(name, args = {})
    render name, args
  rescue ActionView::MissingTemplate
    render "resource_controller/base/#{name}", args
  end
end
