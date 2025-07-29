require "ruby_llm"

RubyLLM.configure do |config|
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY", nil)
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  config.gemini_api_key = ENV["GEMINI_API_KEY"]
  config.default_model = 'gemini-2.0-flash'
end

RubyLLM.models.refresh!
AVAILABLE_MODEL_IDS = RubyLLM.models.all.map(&:id).freeze
