# WhatsApp AI Chatbot

A production-ready **Rails 8** application that creates an intelligent WhatsApp chatbot powered by multiple AI providers (OpenAI, Anthropic, Gemini). The bot automatically responds to WhatsApp messages using configurable AI personalities and maintains conversation context. Uses [WasenderApi](https://wasenderapi.com/) to send WhatsApp messages at low cost (Needs a paid subscription of around $6 per month, free trial available).

![Rails](https://img.shields.io/badge/Rails-8.0.2-red.svg)
![Ruby](https://img.shields.io/badge/Ruby-3.4.2-red.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## ✨ Features

- 🤖 **Multi-Provider AI**: Supports OpenAI, Anthropic, and Gemini models with automatic fallback. By default uses Gemini Flash AI Model which has a generous free tier. All you need is to create an account at [Google AI Studio](https://aistudio.google.com)
- 💬 **WhatsApp Integration**: Full WhatsApp Business API integration via WasenderApi
- 🎭 **Configurable Personas**: Create different AI personalities with custom base prompts
- 📱 **Media Handling**: Detects media messages and replies with a canned response, only sends text messages to LLM Provider for answer.
- 🔐 **Admin Interface**: Web dashboard for managing chats, messages, and personas
- 📊 **Conversation Tracking**: Full message history with token usage analytics
- 🔄 **Background Processing**: Async message processing with idempotent jobs
- 🛡️ **Security**: Webhook signature validation and admin authentication

## 🏗️ Architecture

- **Backend**: Rails 8 with SQLite (production-ready)
- **AI Integration**: `ruby_llm` gem with model fallback system
- **WhatsApp API**: Custom `WasenderApi` library
- **Background Jobs**: Solid Queue with Acidic Job for idempotency
- **Frontend**: Turbo + Stimulus + Tailwind CSS
- **Database**: Conversation-focused schema with Users, Chats, Messages, ToolCalls

## 📋 Requirements

- **Ruby**: 3.4.2+
- **Rails**: 8.0.2+
- **SQLite**: 3.x (included with Rails 8)
- **Wasender WhatsApp Account**: Low cost, Business WhatsApp service.
- **AI API Keys**: At least one of OpenAI, Anthropic, or Gemini

> **Note**: No Node.js required! This project uses Rails 8's Importmap for JavaScript management.

## 🔧 Environment Variables

Create a `.env` file in your project root with these variables:

### Required - WasenderApi Configuration
```bash
# WasenderApi credentials for WhatsApp integration
WASENDER_PERSONAL_ACCESS_TOKEN=your_wasender_token_here
WASENDER_BASE_URL=https://www.wasenderapi.com/api/
WASENDER_PHONE_NUMBER=+1234567890  # Your WhatsApp Business number
```

### Required - AI Provider Keys (at least one)
```bash
# AI model API keys - configure at least one
OPENAI_API_KEY=your_openai_key_here           # For GPT models
ANTHROPIC_API_KEY=your_anthropic_key_here     # For Claude models  
GEMINI_API_KEY=your_gemini_key_here           # For Gemini models (default)
```

### Production Only
```bash
# Rails master key for production (auto-generated)
RAILS_MASTER_KEY=your_rails_master_key_here

# Optional: Database URL for non-SQLite setups
DATABASE_URL=postgresql://user:pass@host:5432/dbname
```

## 🔗 WasenderApi Setup

Before installing the application, you need to set up your WhatsApp integration through WasenderApi.

### 1. Create WasenderApi Account

1. **Register**: Go to [WasenderApi registration page](https://wasenderapi.com/register)
2. **Verify Email**: Fill in your details and verify your email address
3. **Login**: Access your account at [wasenderapi.com/dashboard](https://wasenderapi.com/dashboard)

### 2. Retrieve Personal Access Token
   - You can generate and manage your Personal Access Token from the Settings > Personal Access Token page in your Wasender dashboard.
   1. **Copy Personal Access Token**: This becomes your `WASENDER_PERSONAL_ACCESS_TOKEN`
   2. **Note Your Phone Number**: In E.164 format for `WASENDER_PHONE_NUMBER`

### 3. Create WhatsApp Session

1. **Navigate to Sessions**: In the dashboard, go to the **Sessions** tab
2. **Create New Session**: Click on **"Create New Session"**
3. **Configure Session**:
   - **Name**: Give your session a descriptive name (e.g., "My Chatbot")
   - **Phone Number**: Enter your WhatsApp Business phone number in E.164 format (+1234567890)
   - **Account Protection**: Enable to ensure your number is not blocked by Whatsapp (Implements a rate limit)
   - **Log Messages**: Enable to track message history
   - **Webhook Settings**: 
     - **Webhook URL**: `https://your-domain.com/webhook` (set this after deployment)
     - **Webhook Enabled**: ✅ Enable
     - **Webhook Events**: Select `messages.received` at minimum

4. **Link WhatsApp Account**:
   - A QR code will appear on screen
   - Open WhatsApp on your phone
   - Go to **Settings > Linked Devices**
   - Tap **"Link a Device"** and scan the QR code
   - Your session status will change to **"Connected"**

### 3. Configure Webhooks (After Deployment)

After deploying your Rails application:
1. Return to your WasenderApi dashboard
2. Edit your session settings
3. Set **Webhook URL** to: `https://your-deployed-app.com/webhook`
4. Ensure **Webhook Events** includes:
   - `messages.received` (required)
   - `session.status` (recommended)

> **💡 Tip**: Test your webhook endpoint with tools like ngrok for local development:
> ```bash
> # Install ngrok globally
> npm install -g ngrok
> 
> # In another terminal, expose your local Rails server
> ngrok http 3000
> 
> # Use the ngrok HTTPS URL in WasenderApi webhook settings
> # Example: https://abc123.ngrok.io/webhook
> ```

## 🚀 Local Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/whatsapp-rails-chatbot.git
   cd whatsapp-rails-chatbot
   ```

2. **Install dependencies**
   ```bash
   # Install Ruby gems
   bundle install
   ```

3. **Setup the database**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   bin/rails db:seed
   ```

4. **Configure environment variables**
   ```bash
   # Copy the example file
   cp env.example .env.development
   cp env.example .env.test
   
   # Edit with your actual credentials
   nano .env.development
   nano .env.test
   ```

5. **Start the development server**
   ```bash
   # Start Rails with background jobs
   bin/dev
   
   # Or manually start components:
   bin/rails server          # Rails server on port 3000
   bin/jobs                  # Background job processor
   ```

6. **Create an admin user**
   ```bash
   bin/rails console
   > AdminUser.create!(email_address: "admin@example.com", password: "secure_password")
   ```

## 📱 Usage

1. **Access Admin Dashboard**: Visit `http://localhost:3000` and login
2. **Configure Personas**: Create AI personalities in the admin interface
3. **Setup WhatsApp Webhook**: Point WasenderApi webhooks to `/webhook` endpoint
4. **Start Chatting**: Send messages to your WhatsApp Business number

## 🚀 Deployment

### Heroku Deployment

1. **Prepare for deployment**
   ```bash
   # Create Heroku app
   heroku create your-app-name
   
   # Add environment variables
   heroku config:set WASENDER_PERSONAL_ACCESS_TOKEN=personal-access-token-from-wasender-profile-page
   heroku config:set WASENDER_BASE_URL=https://www.wasenderapi.com/api/
   heroku config:set WASENDER_PHONE_NUMBER=+1234567890
   heroku config:set OPENAI_API_KEY=your_key
   heroku config:set ANTHROPIC_API_KEY=your_key  
   heroku config:set GEMINI_API_KEY=your_key
   heroku config:set SOLID_QUEUE_IN_PUMA=true
   ```

2. **Deploy**
   ```bash
   git push heroku main
   
   # Run migrations
   heroku run rails db:migrate
   heroku run rails db:seed
   
   # Create admin user
   heroku run rails console
   > AdminUser.create!(email_address: "admin@example.com", password: "secure_password")
   ```

3. **Scale workers (optional)**
   ```bash
   heroku ps:scale worker=1  # For background job processing
   ```

### Fly.io Deployment

1. **Install and setup Fly CLI**
   ```bash
   # Install flyctl
   curl -L https://fly.io/install.sh | sh
   
   # Login and create app
   fly auth login
   fly launch --name your-app-name
   ```

2. **Set environment variables**
   ```bash
   # Set secrets (encrypted)
   fly secrets set WASENDER_PERSONAL_ACCESS_TOKEN=personal-access-token-from-wasender-profile-page
   fly secrets set OPENAI_API_KEY=your_key
   fly secrets set ANTHROPIC_API_KEY=your_key
   fly secrets set GEMINI_API_KEY=your_key
   fly secrets set RAILS_MASTER_KEY=$(cat config/master.key)
   
   # Set public environment variables  
   fly secrets set WASENDER_BASE_URL=https://www.wasenderapi.com/api/
   fly secrets set WASENDER_PHONE_NUMBER=+1234567890
   ```

3. **Deploy**
   ```bash
   fly deploy
   ```

4. **Setup Continous Deployment via Github actions**
   ```bash
   fly tokens create deploy -x 999999h
   ```
   * Copy the output, including the FlyV1 and space at the beginning. 

   * Go to your newly-created repository on GitHub and select Settings --> Secrets and Variables --> Actions

   * Create a new repository secret called FLY_API_TOKEN with the value of the token from the fly tokens create command.

### Kamal Deployment (VPS)

Perfect for **Digital Ocean**, **Hetzner**, **Linode**, or any VPS provider.

1. **Setup your VPS**
   ```bash
   # Ensure Docker is installed on your server
   # Update config/deploy.yml with your server IP
   ```

2. **Configure Kamal**
   ```bash
   # Edit config/deploy.yml
   nano config/deploy.yml
   
   # Update these sections:
   servers:
     web:
       - YOUR_SERVER_IP  # e.g., 142.93.123.456
   
   proxy:
     host: your-domain.com  # Your domain name
   
   registry:
     username: your-docker-username
   ```

3. **Setup secrets**
   ```bash
   # Create .kamal/secrets file
   mkdir -p .kamal
   nano .kamal/secrets
   
   # Add your environment variables:
   KAMAL_REGISTRY_PASSWORD=your_docker_hub_token
   RAILS_MASTER_KEY=your_rails_master_key
   WASENDER_PERSONAL_ACCESS_TOKEN=personal-access-token-from-wasender-profile-page
   OPENAI_API_KEY=your_key
   ANTHROPIC_API_KEY=your_key
   GEMINI_API_KEY=your_key
   ```

4. **Deploy**
   ```bash
   # Initial setup (first time only)
   kamal setup
   
   # For subsequent deployments
   kamal deploy
   
   # Useful Kamal commands
   kamal logs          # View logs
   kamal console       # Rails console
   kamal shell         # SSH into container
   ```

### Digital Ocean App Platform

1. **Create app from GitHub**
   - Connect your GitHub repository
   - Choose "Web Service" type
   - Set build command: `bundle exec rails assets:precompile`
   - Set run command: `bundle exec rails server -p $PORT`

2. **Configure environment variables** in the App Platform dashboard:
   ```
   WASENDER_PERSONAL_ACCESS_TOKEN
   WASENDER_BASE_URL
   WASENDER_PHONE_NUMBER  
   OPENAI_API_KEY
   ANTHROPIC_API_KEY
   GEMINI_API_KEY
   RAILS_MASTER_KEY
   RAILS_ENV=production
   ```

## 🔧 Development

### Running Tests
```bash
# Run all tests
bin/rails test

# Run specific test files
bin/rails test test/models/chat_test.rb
bin/rails test test/controllers/webhooks_controller_test.rb

# Run with coverage
bin/rails test COVERAGE=true
```

### Code Quality
```bash
# Ruby linting (Omakase style)
bin/rubocop
bin/rubocop -A  # Auto-correct violations

# Security analysis
bin/brakeman

# Check for outdated gems
bundle outdated
```

### Development Console
```bash
# Rails console with Pry
bin/rails console

# Database console
bin/rails dbconsole

# Useful console commands:
User.count                    # Check user count
Chat.includes(:messages).all  # Load chats with messages
WasenderApi.get_session_id("+1234567890")  # Test API
```

### Database Management
```bash
# Create and run migrations
bin/rails generate migration AddFieldToModel field:type
bin/rails db:migrate

# Reset database (development only)
bin/rails db:reset

# Generate model annotations
bin/rails annotate_models
```

## 🏛️ Architecture Details

### Database Schema
- **Users**: WhatsApp phone numbers with conversation history
- **Chats**: Conversation sessions with assigned AI models
- **Messages**: Individual messages with role, content, and token tracking
- **ToolCalls**: AI function calls with arguments and responses
- **Personas**: Configurable AI personalities with base prompts
- **AdminUsers**: Authentication for web interface access

### Message Flow
1. WhatsApp → WasenderApi → `/webhook` endpoint
2. `ProcessWebhook` interaction validates and queues message
3. `ProcessWhatsappMessageJob` processes message with AI
4. Response sent back through WasenderApi to WhatsApp

### AI Model Configuration
- **Default**: Gemini 2.0 Flash (fast and cost-effective)
- **Fallback**: GPT-4.1 Nano (if Gemini unavailable)
- **Supported**: All OpenAI, Anthropic, and Google models via `ruby_llm`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and add tests
4. Run the test suite (`bin/rails test`)
5. Run linting (`bin/rubocop`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [WasenderApi](https://wasenderapi.com/) for WhatsApp Business API
- [ruby_llm](https://github.com/patterns-ai-core/ruby-llm) for multi-provider AI integration
- [Rails 8](https://rubyonrails.org/) for the modern web framework
- [Kamal](https://kamal-deploy.org/) for simple production deployment

---

⭐ **Star this repository if you found it helpful!**