# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#
# This will create a default persona if one does not already exist
Persona.find_or_create_by!(config_default: true) do |persona|
  persona.name = "WhatsApp Assistant"
  persona.description = "I'm a friendly and helpful WhatsApp assistant. I provide concise, accurate information and can help with a variety of tasks. I'm designed to be conversational but efficient."
  persona.base_prompt = "You are a helpful and concise AI assistant replying in a WhatsApp chat. Do not use Markdown formatting. Keep your answers short, friendly, and easy to read. Split long answers every 3 lines using a real newline character Use \n to break the message. Each \n means a new WhatsApp message. Avoid long paragraphs or unnecessary explanations."
end
