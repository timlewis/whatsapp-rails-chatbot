require "ruby_llm"

RubyLLM.models.refresh!
AVAILABLE_MODEL_IDS = RubyLLM.models.all.map(&:id).freeze
DEFAULT_LLM_MODEL = AVAILABLE_MODEL_IDS.detect { |id| id == 'gemini-2.0-flash' } || 'gpt-4.1-nano'

RubyLLM.configure do |config|
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY", nil)
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  config.gemini_api_key = ENV["GEMINI_API_KEY"]
  config.default_model = DEFAULT_LLM_MODEL
end
