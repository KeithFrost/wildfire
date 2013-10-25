worker_processes 40
listen '0.0.0.0:6969'
timeout 300

working_directory '/var/wildfire/app/current'
stdout_path       '../../shared/log/app.log'
stderr_path       '../../shared/log/error.log'
pid               '../../shared/pids/unicorn.pid'

before_fork do |server, worker|
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end