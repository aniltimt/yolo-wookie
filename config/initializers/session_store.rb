# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_manager_session',
  :secret      => 'c83f2ed491de2d878f97948e0d7aaf7e513376698abfff2e0e500086c1dc7006ca4b891a848314f80fd9506c2d6598936c0d380b57a889df4b662876f8f91894'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :active_record_store
