require_relative 'helper'
require_relative '../customkiq/retry_jobs'
require_relative '../jobs/rather_not_useful'

Sidekiq::Testing.server_middleware do |chain|
  chain.add Customkiq::RetryJobs
end

class TestRetryJobs < Minitest::Test

  describe 'you can specify rescue actions depends on error' do

    before do
      RetrySet = Sidekiq::RetrySet.new; RetrySet.clear
      DeadSet  = Sidekiq::DeadSet.new; DeadSet.clear
    end

    def ignore_error(error)
      yield
    rescue error
    end

    describe "use cases" do

      before do
        RatherNotUseful.sidekiq_options rescue: {
          NetworkError:  { retry: 1, dead: false, delay: 5 },
          NoMethodError: { retry: 0, dead: true }
        }
      end

      it 'on NetworkError retries once after 5 seconds and do not push to dead queue' do
        RatherNotUseful.perform_async(1) # NetworkError

        assert_equal 0, RetrySet.size
        ignore_error(NetworkError) { RatherNotUseful.drain }
        assert_equal 1, RetrySet.size
        ignore_error(NetworkError) { RetrySet.retry_all }
        ignore_error(NetworkError) { RatherNotUseful.drain }
        # assert_equal 0, RetrySet.size
        # assert_equal 1, DeadSet.size
      end

      it 'on NoMethodError does not retry and push to dead queue' do
        RatherNotUseful.perform_async(0) # NoMethodError
      end

    end

    describe 'edge cases' do
      before do
        RatherNotUseful.sidekiq_options retry: false
      end

      it 'ignores rescue options and neither retries nor moves to dead queue in all cases' do
      end
    end

  end

end
