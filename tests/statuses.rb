require 'minitest/autorun'
require_relative '../customkiq/statuses'

class TestStatuses < Minitest::Test

  describe "adds on status change hooks to Sidekiq" do

    before do
      @counter = 0
    end

    describe Customkiq::Statuses::Hook do
      let(:hook) { Customkiq::Statuses::Hook.new }

      it "has a stack of handlers" do
        assert_equal 0, hook.handlers.size
        hook.handlers << :handler
        assert_equal 1, hook.handlers.size
      end

      let(:handler) { ->{ @counter += 1 } }

      it "calls all handlers on handle_change" do
        hook.handlers << handler
        hook.handlers << handler
        hook.handle_change
        assert_equal 2, @counter
      end
    end

    it "provides 4 default Hooks" do
      assert_instance_of Customkiq::Statuses::Hook, Customkiq::Statuses::Queued
      assert_instance_of Customkiq::Statuses::Hook, Customkiq::Statuses::Processing
      assert_instance_of Customkiq::Statuses::Hook, Customkiq::Statuses::Failed
      assert_instance_of Customkiq::Statuses::Hook, Customkiq::Statuses::Completed
    end

    describe Customkiq::Statuses::Lifecycle do
      before do
        Customkiq::Statuses::Processing.handlers.clear
        Customkiq::Statuses::Failed.handlers.clear
        Customkiq::Statuses::Completed.handlers.clear
      end

      let(:lifecycle) { Customkiq::Statuses::Lifecycle.new }
      let(:handler) { ->(a, b, c){ @counter += 1 } }
      let(:failed_handler) { ->(a, b, c, d){ @counter = 0 } }

      class SomethingHappened < TypeError; end

      it "uses Processing, Failed, Completed hooks during job lifecycle" do
        Customkiq::Statuses::Processing.handlers << handler
        Customkiq::Statuses::Completed.handlers  << handler
        Customkiq::Statuses::Failed.handlers  << failed_handler

        lifecycle.call(nil, nil, nil) { :everything_fine }
        assert_equal 2, @counter

        begin
          lifecycle.call(nil, nil, nil) { raise SomethingHappened }
        rescue SomethingHappened
        end
        assert_equal 0, @counter
      end

    end

    describe Customkiq::Statuses::Client::Lifecycle do
      let(:client_lifecycle) { Customkiq::Statuses::Client::Lifecycle.new }
      let(:handler) { ->(a, b, c, d){ @counter += 1 } }

      it "uses Queued hook after adding a job" do
        Customkiq::Statuses::Queued.handlers << handler

        assert_equal :everything_fine, client_lifecycle.call(nil, nil, nil, nil) { :everything_fine }
        assert_equal 1, @counter
      end
    end

  end

end
