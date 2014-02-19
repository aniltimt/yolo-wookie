# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_view.debug_rjs                         = true

# mimic production environment
config.action_view.cache_template_loading            = true
config.action_controller.perform_caching             = true #false
config.action_controller.consider_all_requests_local = false #true
config.cache_classes = true # false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false
config.action_mailer.delivery_method = :sendmail
config.action_mailer.default_url_options = { :host => 'qa.tour-builder.digital-footsteps.com' }
