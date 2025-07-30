# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8 application that implements a WhatsApp chatbot integrated with AI models via the `ruby_llm` gem. The application processes WhatsApp messages through webhooks and generates AI responses using configurable LLM models (OpenAI, Anthropic, Gemini).

## Key Architecture

- **WhatsApp Integration**: Uses WasenderApi for WhatsApp messaging (custom API wrapper in `lib/wasender_api.rb`)
- **AI Integration**: Uses `ruby_llm` gem with configurable models (Gemini 2.0 Flash as default, fallback to GPT-4.1 Nano)
- **Message Processing**: Webhook-based message handling in `WebhooksController`
- **Database Design**: Chat-based conversation structure with Messages, ToolCalls, Users, and Personas
- **Job Processing**: Uses Solid Queue for background jobs and Acidic Job for idempotent workflows

## Database Schema

Core models follow a conversational AI pattern:
- `User` (WhatsApp phone numbers)
- `Chat` (conversation sessions with AI model assignment)
- `Message` (individual messages with role, content, tokens)
- `ToolCall` (AI function calls with JSON arguments)
- `Persona` (AI personality configurations with base prompts)

## Common Development Commands

**Setup and Dependencies:**
```bash
bin/setup              # Initial setup
bundle install         # Install gems
```

**Database:**
```bash
bin/rails db:create db:migrate db:seed
bin/rails db:reset     # Reset database
```

**Testing:**
```bash
bin/rails test         # Run all tests (uses Minitest with Mocha for mocking)
bin/rails test test/models/chat_test.rb    # Run specific test file
```

**Development Server:**
```bash
bin/dev                # Start development server
```

**Code Quality:**
```bash
bin/rubocop           # Run Ruby linter (Omakase style)
bin/brakeman          # Security analysis
```

**Console:**
```bash
bin/rails console     # Rails console with Pry
```

## Environment Configuration

Required environment variables:
- `WASENDER_PERSONAL_ACCESS_TOKEN` - WasenderApi authentication
- `WASENDER_BASE_URL` - WasenderApi endpoint
- `WASENDER_PHONE_NUMBER` - WhatsApp business number
- `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` - AI model keys

## Key Files and Locations

- `config/initializers/ruby_llm.rb` - AI model configuration
- `lib/wasender_api.rb` - WhatsApp API wrapper with message handling
- `app/controllers/webhooks_controller.rb` - WhatsApp webhook processing
- `app/models/` - Core conversation models with RubyLLM integration
- `test/` - Minitest suite with fixtures and mocking

## Development Notes

- Uses Rails 8 defaults including Solid Cache, Solid Queue, and Solid Cable
- Configured for SQLite in development/test, production-ready with other adapters
- Message splitting logic handles WhatsApp's character limits
- Webhook signature validation for security
- Annotate gem maintains model documentation