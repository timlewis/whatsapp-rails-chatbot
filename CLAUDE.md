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
bin/rubocop           		      # Run Ruby linter (Omakase style)
bin/rubocop -A 			  		      # Auto-correct RuboCop violations
bin/rubocop --only <cop_name> 	# Run specific RuboCop cop
bin/brakeman          		      # Security analysis
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

## Rails 8 Project Structure

```
myapp/
├── app/
│   ├── models/              # ActiveRecord models
│   ├── controllers/         # ActionController controllers
│   ├── views/              # ERB/HAML templates
│   ├── helpers/            # View helpers
│   ├── mailers/            # ActionMailer mailers
│   ├── jobs/               # ActiveJob jobs (Solid Queue)
│   ├── assets/             # Application assets (Propshaft)
│   └── javascript/         # JavaScript files
├── config/
│   ├── application.rb      # Application configuration
│   ├── routes.rb           # URL routing
│   ├── database.yml        # Database configuration
│   ├── deploy.yml          # Kamal 2 deployment config (NEW)
│   └── environments/       # Environment-specific configs
├── db/
│   ├── migrate/            # Database migrations
│   └── seeds.rb           # Database seeds
├── test/                   # Test files (default in Rails 8)
│   ├── models/
│   ├── controllers/
│   ├── integration/
│   └── system/
├── bin/                    # Binstubs
├── config.ru              # Rack configuration
├── Gemfile                 # Gem dependencies
├── Gemfile.lock           # Locked gem versions
└── Dockerfile             # Docker configuration (if using containers)
```

## Rails 8 New Features Integration

### 1. SQLite Production Enhancements
Rails 8 makes SQLite production-ready:

```ruby
# config/database.yml
production:
  adapter: sqlite3
  database: storage/production.sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  # New Rails 8 SQLite configurations
  pragmas:
    busy_timeout: 1000
    journal_mode: WAL
    synchronous: NORMAL
    foreign_keys: true
```

### 2. Solid Trifecta Configuration

#### Solid Queue (Background Jobs)
```ruby
# config/application.rb
config.active_job.queue_adapter = :solid_queue

# app/jobs/sample_job.rb
class SampleJob < ApplicationJob
  queue_as :default
  
  def perform(user)
    # Background job logic
  end
end
```

#### Solid Cache (Caching)
```ruby
# config/application.rb
config.cache_store = :solid_cache_store

# Usage in controllers/models
Rails.cache.fetch("user_#{user.id}", expires_in: 1.hour) do
  expensive_calculation(user)
end
```

#### Solid Cable (WebSockets)
```ruby
# config/application.rb
config.action_cable.adapter = :solid_cable

# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end
end
```

### 3. Native Authentication (Rails 8)
```ruby
# Generate authentication
bin/rails generate authentication User

# app/models/user.rb (generated)
class User < ApplicationRecord
  has_secure_password
  
  validates :email, presence: true, uniqueness: true
  normalizes :email, with: ->(email) { email.strip.downcase }
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  
  private
  
  def authenticate_user!
    redirect_to login_path unless current_user
  end
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
end
```

### 4. Propshaft Asset Pipeline
```ruby
# config/application.rb
# Propshaft is now the default - no configuration needed

# Assets are automatically fingerprinted and served
# Use asset helpers in views:
<%= asset_path("application.css") %>
<%= asset_path("logo.png") %>
```

## Testing in Rails 8

### Default Test Suite Setup
Rails 8 includes comprehensive testing setup by default:

```ruby
# test/test_helper.rb
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)
    
    # Setup all fixtures in test/fixtures/*.yml
    fixtures :all
    
    # Add more helper methods to be used by all tests here...
  end
end
```
## Security Best Practices (Rails 8)

### Built-in Security Features
- **Brakeman** - Included by default for security scanning
- **Credential Management** - Use `rails credentials:edit`
- **Content Security Policy** - Configure in `application_controller.rb`
- **Force SSL** - Enable in production environment

```ruby
# config/environments/production.rb
config.force_ssl = true
config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data
  policy.object_src  :none
  policy.script_src  :self, :https
  policy.style_src   :self, :https, :unsafe_inline
end
```

## Performance Optimization

### Database Optimization
```ruby
# Use includes to avoid N+1 queries
@users = User.includes(:posts).all

# Use counter_cache for associations
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end
```

### Caching Strategies
```ruby
# Fragment caching in views
<% cache @user do %>
  <%= render @user %>
<% end %>

# Action caching in controllers
class UsersController < ApplicationController
  caches_action :index, expires_in: 1.hour
end
```