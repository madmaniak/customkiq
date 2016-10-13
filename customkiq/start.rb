require 'sidekiq'
require_relative './retry_jobs'

NS = 'customkiq'

Sidekiq.configure_client do |config|
  config.redis = { :namespace => NS, :size => 1 }
end

Sidekiq.configure_server do |config|
  config.redis = { :namespace => NS }
  config.server_middleware do |chain|
    chain.remove Sidekiq::Middleware::Server::RetryJobs
    chain.add Customkiq::RetryJobs
  end
end

Sidekiq::Logging.logger.level = Logger::DEBUG

Dir['jobs/**/*'].each do |path|
  require "./#{path}"
end
