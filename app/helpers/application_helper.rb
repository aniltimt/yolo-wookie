# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def show_build_info
    build_info = if File.exists?(Rails.root.join('public', 'version.txt'))
      info = File.read(Rails.root.join('public', 'version.txt'))
      parts = info.split(/Git hash/)
      parts.empty? ? info : parts.first.strip
    else
      'Build number not available'
    end

    content_tag :div, build_info, {:class => "build_info"}
  end

  def coordinates_of(model, opts={ })
    content_tag(:span, "#{model.lat}; #{model.lng}", opts.merge(:class => 'geo'))
  end

  def tab(name, path, active)
    link_to (active ? content_tag(:strong, name) : name), path
  end

  def render_media(model, opts={ })
    partial_name = model.class.name.underscore
    opts = opts.merge(:object => model, :partial => "media/#{partial_name}")
    render opts
  end

  def medium_css_class(medium)
    case medium
      when Picture: 'picture'
      when Audio: 'audio'
      when Video: 'video'
      when TextPage: 'text-page'
    end
  end

   def tour_status(tour)
     tour.aasm_state
   end
end
