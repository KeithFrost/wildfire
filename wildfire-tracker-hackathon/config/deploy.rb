set :application, 'wildfire'
set :repository, '.'

set :user, 'root'
set :use_sudo, false
set :scm, :none
set :deploy_via, :copy

role :app, '<host>'

default_run_options[:pty] = true
ssh_options[:forward_agent] = true
ssh_options[:keys] = ['~/.ssh/torrent_deploy.pem']

set :wildfire_path, '/var/wildfire'
set :deploy_to,     File.join(wildfire_path, 'app')
set :unicorn,      '/usr/local/bin/unicorn'
set :unicorn_pid,  "#{deploy_to}/shared/pids/unicorn.pid"
set :unicorn_conf, "#{deploy_to}/current/config/unicorn.rb"

namespace :deploy do
  task :restart do
    run "if [ -f #{unicorn_pid} ]; then kill -USR2 `cat #{unicorn_pid}`; else cd #{deploy_to}/current && #{unicorn} -c #{unicorn_conf} -D; fi"
  end

  task :start do
    run "cd #{deploy_to}/current && #{unicorn} -c #{unicorn_conf} -D"
  end

  task :stop do
    run "if [ -f #{unicorn_pid} ]; then kill -QUIT `cat #{unicorn_pid}`; fi"
  end

  task :symlink_wildfire do
    [:repos, :torrents, :downloads].map(&:to_s).each do |path|
      source = File.join wildfire_path, path
      target = File.join deploy_to, 'current', path

      run "ln -s #{source} #{target}"
    end
  end
end

after "deploy:update",  "deploy:symlink_wildfire"
after "deploy:restart", "deploy:cleanup"