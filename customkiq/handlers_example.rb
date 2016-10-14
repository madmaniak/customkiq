Customkiq::Statuses::Queued.handlers << ->(*args){
  Sidekiq.logger.debug "I was queued - said #{args[1]}"
}

Customkiq::Statuses::Processing.handlers << ->(worker, item, queue){
  Sidekiq.logger.debug "I am processing - said #{item}"
}

Customkiq::Statuses::Failed.handlers << ->(worker, item, queue, e){
  Sidekiq.logger.debug "I was wrong, I'm so sorry - said #{item}"
}

Customkiq::Statuses::Completed.handlers << ->(worker, item, queue){
  Sidekiq.logger.debug "I am complete - said #{item}"
}
