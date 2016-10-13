class RatherNotUseful

  include Sidekiq::Worker

  sidekiq_options rescue: {
    NetworkError:  { retry: 5, dead: false, delay: 10 },
    NoMethodError: { retry: 0, dead: true }
  }

  def perform(i = nil)
    case i || rand(0..2)
    when 0 then nil.im_not_a_method # NoMethodError
    when 1 then raise NetworkError
    else puts "I feel lucky!"
    end
  end
end

class NetworkError < TypeError; end
