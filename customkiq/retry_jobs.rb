require 'sidekiq/middleware/server/retry_jobs'

module Customkiq

  class RetryJobs < Sidekiq::Middleware::Server::RetryJobs

    ## example usage in Worker:
    #
    # sidekiq_options rescue: {
    #   NetworkError:  { retry: 5, dead: false, delay: 60 },
    #   NoMethodError: { retry: 0, dead: true }
    # }

    private

    def attempt_retry(worker, msg, queue, exception)
      rescue_opts(worker, exception) do |opts|
        msg['retry'] = opts[:retry]
        msg['dead']  = opts[:dead]
      end
      super
    end

    def delay_for(worker, count, exception)
      rescue_opts(worker, exception) do |opts|
        opts[:delay]
      end || super
    end

    def rescue_opts(worker, exception)
      if rescue_opts = worker.sidekiq_options_hash['rescue']
        exception_opts = rescue_opts[exception.class.to_s.to_sym]
        yield exception_opts if exception_opts
      end
    end

  end
end
