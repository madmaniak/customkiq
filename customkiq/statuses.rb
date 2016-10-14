module Customkiq
  module Statuses

    class Hook

      attr_reader :handlers

      def initialize
        @handlers = []
      end

      def handle_change(*args)
        @handlers.each do |handler|
          handler.call(*args)
        end
      rescue => ex
        Sidekiq.logger.error "!!! STATUS HOOK THREW AN ERROR !!!"
        Sidekiq.logger.error ex
        Sidekiq.logger.error ex.backtrace.join("\n") unless ex.backtrace.nil?
      end

    end

    Queued = Hook.new
    Processing = Hook.new
    Failed    = Hook.new
    Completed = Hook.new

    class Lifecycle

      def call(worker, item, queue)
        Processing.handle_change(worker, item, queue)
        yield
        Completed.handle_change(worker, item, queue)
      rescue Exception => e
        Failed.handle_change(worker, item, queue, e)
        raise e
      end

    end

    module Client
      class Lifecycle

        def call(worker_class, item, queue, redis_pool)
          result = yield
          Customkiq::Statuses::Queued.handle_change(worker_class, item, queue, redis_pool)
          result
        end

      end
    end

  end
end
