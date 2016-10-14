require 'sidekiq'
require_relative './retry_jobs'
require_relative './statuses'

NS = 'customkiq'

Sidekiq.configure_client do |config|
  config.redis = { :namespace => NS, :size => 1 }
  config.client_middleware do |chain|
    chain.add Customkiq::Statuses::Client::Lifecycle
  end
end

Sidekiq.configure_server do |config|
  config.redis = { :namespace => NS }
  config.server_middleware do |chain|
    chain.remove Sidekiq::Middleware::Server::RetryJobs
    chain.add Customkiq::RetryJobs
    chain.add Customkiq::Statuses::Lifecycle
  end
end

Sidekiq::Logging.logger.level = Logger::DEBUG

Dir['jobs/**/*'].each do |path|
  require "./#{path}"
end

require_relative './handlers_example'
