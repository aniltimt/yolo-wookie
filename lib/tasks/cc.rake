
namespace :cruise do
  desc "Prepare CC environment"
  task :prepare_env do
    ENV["RAILS_ENV"] = 'cruise'
    Rake::Task['db:migrate'].invoke
  end
end

task :cruise => ['cruise:prepare_env', 'spec']
