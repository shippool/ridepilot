class ChatWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform(message_id)
    Rails.logger.info "ChatWorker#perform"
    message = RoutineMessage.find_by_id message_id
    if message
      ActionCable.server.broadcast "chat_channel_#{message.provider_id}_#{message.driver_id}", {
        sender_id: message.sender_id, 
        sender_name: message.sender.try(:display_name),
        body: message.body, 
        driver_id: message.driver_id,
        provider_id: message.provider_id,
        action: 'CreateMessage',
        created_at: message.created_at,
        id: message.id
      }

      ActionCable.server.broadcast "chat_alert_channel_#{message.run_id}", {
        message_id: message.id,
        sender_id: message.sender_id,
        action: 'NewChat'
      }
    end
  end
end
