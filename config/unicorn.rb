# config/unicorn.rb
worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
timeout 15
preload_app true

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ApplicationRecord) and
    ApplicationRecord.connection.disconnect!
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  if defined?(ApplicationRecord)
    config = ApplicationRecord.configurations[Rails.env] ||
      Rails.application.config.database_configuration[Rails.env]
    config['adapter'] = 'postgis'
    ApplicationRecord.establish_connection(config)
  end

end