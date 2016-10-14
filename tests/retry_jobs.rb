require 'minitest/autorun'
require_relative '../customkiq/retry_jobs'

# <stubs>

module Sidekiq
  module Middleware
    module Server
      class RetryJobs
        private

        def attempt_retry(worker, msg, queue, exception)
          msg
        end

        def delay_for(worker, count, exception)
          13
        end
      end
    end
  end
end

class DummyWorker
  def sidekiq_options_hash
    { 'retry' => 5, 'dead' => true, 'rescue' =>
      { NetworkError:  { retry: 1, dead: false, delay: 60 } }
    }
  end
end

class NetworkError < TypeError; end

# </stubs>

class TestRetryJobs < Minitest::Test

  describe 'fixes to Sidekiq - you can specify rescue actions depends on an error' do

    let(:worker) { DummyWorker.new }

    describe "attempt_retry" do

      def attempt_retry(exception)
        Customkiq::RetryJobs.new.send(:attempt_retry, worker, worker.sidekiq_options_hash, nil, exception)
      end

      describe "error doesn't match" do
        it "leaves default behavior" do
          assert_equal worker.sidekiq_options_hash, attempt_retry(Exception.new)
        end
      end

      describe "error match rescue configuration" do
        it "changes default configuration to the matched one from the rescue" do
          result = attempt_retry(NetworkError.new)
          refute_equal worker.sidekiq_options_hash, result
          assert_equal result['retry'], worker.sidekiq_options_hash['rescue'][:NetworkError][:retry]
          assert_equal result['dead'], worker.sidekiq_options_hash['rescue'][:NetworkError][:dead]
        end
      end

    end

    describe 'delay_for' do

      def delay_for(exception)
        Customkiq::RetryJobs.new.send(:delay_for, worker, nil, exception)
      end

      describe "error doesn't match" do
        it "leaves default behavior" do
          assert_equal delay_for(Exception.new), 13
        end
      end

      describe "error match rescue configuration" do
        it "returns number defined in rescue configuration" do
          assert_equal delay_for(NetworkError.new), 60
        end
      end

    end
  end
end
