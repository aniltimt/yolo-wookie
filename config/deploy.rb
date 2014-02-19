$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"
set :rvm_ruby_string, '1.8.7'
set :rvm_type, :user

set :application, "tour_builder"

set :user, "deploy"
set :use_sudo, false

set :repository,  "git@tanker:df.git"
set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :rails_env, "staging"
set :scm, :git
set :rake, "bundle exec rake"
set :branch, "development"

role :web, "10.1.0.175"
role :app, "10.1.0.175"
role :db, "10.1.0.175", :primary => true # This is where Rails migrations will run

def run_wp cmd
  run "cd #{release_path} && #{cmd}"
end

namespace :deploy do
  task :share_links do
    run_wp "ln -nfs #{deploy_to}/#{shared_dir}/database.yml #{release_path}/config/database.yml"
    run_wp "ln -nfs #{deploy_to}/#{shared_dir}/builds #{release_path}/public/builds"
  end

  task :stop do ; end

  task :start do ; end

  task :restart do
    run_wp "touch tmp/restart.txt"
  end

  task :restart_god_monitoring do
    run_wp "god restart delayed_job"
  end
end

namespace 'bundle' do
  task 'install' do
    run_wp "bundle install"
  end
end

after 'deploy:update_code', 'deploy:share_links'
after 'deploy:update_code', 'deploy:restart_god_monitoring'
#after 'deploy:update_code', 'bundle:install'
