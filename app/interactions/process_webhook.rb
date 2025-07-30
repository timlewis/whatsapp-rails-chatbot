class ProcessWebhook < ActiveInteraction::Base
  string :event
  hash :data do
    hash :key do
      string :id
      boolean :fromMe
      string :remoteJid
    end
    hash :message
  end

  validates :event, presence: true, inclusion: { in: WasenderApi::WEBHOOK_EVENTS }

  def execute
    user = find_or_create_user

    {
      user: user,
      message_data: data
    }
  end

  private

  def find_or_create_user
    whatsapp_number = data[:key][:remoteJid]
    User.find_or_create_by(whatsapp_number: whatsapp_number)
  end
end
