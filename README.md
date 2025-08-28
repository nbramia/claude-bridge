# Claude Bridge - Remote Control for Claude Code

**Control Claude Code on your Mac from your iPhone using voice commands and a beautiful live view interface.**

A secure, private system that lets you continue your AI-powered development workflow while on the go. Send voice messages from your iPhone, and see Claude's responses in real-time through a mobile-optimized web interface.

## ⚡ Quick Start

1. **Install Tailscale** on Mac and iPhone, sign in to same account
2. **Run setup**: `./setup.sh` (creates bridge server and configures everything)
3. **Start Claude Code**: `tmux attach -t claude && cd ~/Documents/Code && claude`
4. **Create iOS Shortcut** (3 actions: dictate → send → open live view)
5. **Use from anywhere**: Tap shortcut → dictate → see responses in Safari

**That's it!** You can now control Claude Code from your iPhone while on the go.

## 🎯 What This Does

- **Voice to Claude**: Dictate messages on your iPhone that get sent directly to Claude Code on your Mac
- **Live View**: See Claude's responses in real-time through a beautiful, mobile-optimized web interface
- **Secure & Private**: Uses Tailscale for encrypted, private network access - no public internet exposure
- **Always Available**: Keep your development session running while you're away from your computer

## 🚀 Key Features

- **🎤 Voice Commands**: Dictate messages from your iPhone to Claude Code
- **📱 Mobile-Optimized Live View**: Beautiful, full-screen interface for reading Claude's responses
- **🔒 Secure & Private**: Tailscale-only access with HTTPS encryption
- **⚡ Real-Time Updates**: See Claude's responses as they're generated
- **🔄 Manual Refresh**: Control when to check for new responses
- **📌 Sticky Header**: Always-accessible refresh button and status
- **🎯 Clean Integration**: Direct text submission to Claude Code without shell commands

## 🏗️ Architecture

```
iPhone → Tailscale → Mac → Claude Bridge → tmux → Claude Code (AI Chat)
```

1. **iPhone**: iOS Shortcut captures voice input and sends HTTP requests
2. **Tailscale**: Secure VPN connection between devices
3. **Mac**: FastAPI server receives messages and manages tmux
4. **tmux**: Reliable command injection and output capture
5. **Claude Code**: AI-powered development assistant that you chat with

## 📋 Prerequisites

- macOS with Homebrew
- iPhone with iOS Shortcuts app
- Tailscale account (free tier works)
- Python 3.8+ (installed via uv)
- Claude Code installed and accessible via `claude` command

## ⚠️ Manual Steps Required

**These steps cannot be automated and must be done manually:**

### 1. Tailscale Account Setup
- Go to [tailscale.com](https://tailscale.com) and create a free account
- Sign in with Google, GitHub, or other supported providers
- This creates your personal tailnet

### 2. Tailscale App Installation
- **On Mac**: Download from [tailscale.com/download](https://tailscale.com/download) or use `brew install tailscale`
- **On iPhone**: Install from the App Store
- Sign in to both apps with the same account

### 3. MagicDNS Configuration
- Go to [login.tailscale.com/admin/dns](https://login.tailscale.com/admin/dns)
- Enable MagicDNS for your tailnet
- This allows you to use `your-mac.your-tailnet.ts.net` URLs

### 4. iOS Shortcut Creation
- Follow the detailed guide in [ios-shortcut-guide.md](ios-shortcut-guide.md)
- This requires manual setup in the Shortcuts app

## 🛠️ Installation

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-bridge.git
cd claude-bridge

# Make scripts executable
chmod +x *.sh

# Run the main setup script
./setup.sh
```

### 2. Configure Tailscale

```bash
# Install and configure Tailscale
./tailscale-setup.sh

# On your iPhone:
# 1. Install Tailscale from App Store
# 2. Sign in with same account
# 3. Enable VPN connection
```

### 3. Expose the Bridge

```bash
# Make bridge accessible from iPhone (uses PORT from .env)
tailscale serve --https=443 --bg localhost:8008

# Verify it's working
tailscale serve status
```

### 4. Test the Setup

```bash
# Verify everything is working
./test-bridge.sh
```

## 📱 iOS Shortcut Setup

### Quick Setup (3 Steps)

1. **Create New Shortcut** in the Shortcuts app
2. **Add Actions** in this exact order:
   - **Dictate Text** (to capture your voice input)
   - **Get Contents of URL** (POST request to send message)
   - **Get Contents of URL** (GET request to open live view)
3. **Configure the URLs** (see details below)

### Detailed Shortcut Configuration

#### Action 1: Dictate Text
- **Action**: "Dictate Text"
- **Settings**: Default (no changes needed)

#### Action 2: Send Message (POST Request)
- **Action**: "Get Contents of URL"
- **URL**: `https://YOUR-MAC-NAME.YOUR-TAILNET.ts.net/send`
- **Method**: `POST`
- **Headers**: 
  - `Authorization`: `Bearer YOUR_TOKEN_HERE`
  - `Content-Type`: `application/json`
- **Request Body**: 
  ```json
  {
    "text": "[Dictated Text]",
    "mode": "ask"
  }
  ```

#### Action 3: Open Live View (GET Request)
- **Action**: "Get Contents of URL" 
- **URL**: `https://YOUR-MAC-NAME.YOUR-TAILNET.ts.net/jobs/[Response from URL]/live`
- **Method**: `GET`
- **Headers**: None
- **Request Body**: None

### Finding Your URLs and Token

```bash
# Get your Mac's Tailscale name and tailnet
tailscale status

# Get your authentication token
cat ~/.claude-bridge/token.txt

# Test your setup
curl -s https://YOUR-MAC-NAME.YOUR-TAILNET.ts.net/healthz
```

**Example URLs:**
- Send message: `https://your-mac.your-tailnet.ts.net/send`
- Live view: `https://your-mac.your-tailnet.ts.net/jobs/abc123/live`

## 🔧 Configuration

### Environment Variables

The bridge server is configured via `~/.claude-bridge/.env`. Copy the template and customize:

```bash
# Copy the template
cp claude-bridge.env.template ~/.claude-bridge/.env

# Edit with your preferences
nano ~/.claude-bridge/.env
```

**Key Configuration Options:**
```bash
PORT=8008                           # Local port for the bridge
HOST=127.0.0.1                     # Host to bind to
TMUX_SESSION=claude                 # tmux session name
TMUX_TARGET=claude:0.0             # tmux session and pane
MAX_CAPTURE_LINES=2000             # Max lines to capture
CAPTURE_DELAY_MS=1500              # Wait time after sending command
BRIDGE_BASE_DIR=$HOME/.claude-bridge # Base directory for data
BEARER_TOKEN_FILE=$HOME/.claude-bridge/token.txt # Authentication token
LOG_FILE=$HOME/.claude-bridge/logs/bridge.log # Log file location
VENV_PATH=$HOME/.venvs/claude-bridge # Python virtual environment
BIN_DIR=$HOME/bin                   # Binary directory
LAUNCH_AGENT_ID=com.user.claude-bridge # LaunchAgent identifier
```

### Authentication

Your authentication token is automatically generated and stored in `~/.claude-bridge/token.txt`. This token is required for all API requests.

## 🚀 Getting Started - Complete Workflow

### Before Leaving the House

Follow these steps to prepare your Mac for remote access:

#### 1. **Ensure Bridge Server is Running**
```bash
# Check if bridge server is running
ps aux | grep claude_bridge_server

# If not running, start it:
cd ~ && source ~/.claude-bridge/venv/bin/activate && nohup python ~/bin/claude_bridge_server.py > ~/.claude-bridge/logs/bridge.log 2>&1 &
```

#### 2. **Start Claude Code in tmux**
```bash
# Attach to the tmux session (creates it if it doesn't exist)
tmux attach -t claude || tmux new -s claude

# Navigate to your desired working directory
cd ~/Documents/Code  # or wherever you want to work

# Start Claude Code
claude

# ✅ You should see "Welcome to Claude Code!" message
# ✅ Claude Code is now ready to receive remote commands

# Detach from tmux (keeps Claude running in background)
# Press: Ctrl+B, then D
```

#### 3. **Verify Remote Access**
```bash
# Test that Tailscale serve is working
tailscale serve status

# Should show something like:
# https://your-mac.your-tailnet.ts.net (tailnet only)
#   └── / -> http://127.0.0.1:8008

# Quick test from your Mac
curl -s http://localhost:8008/healthz
# Should return: {"ok":true,"tmux_target":"claude:0.0"}
```

#### 4. **Prevent Computer Sleep (Critical!)**
```bash
# Prevent your Mac from sleeping while you're away
caffeinate -d &

# Or use System Preferences:
# System Preferences > Energy Saver > Prevent computer from sleeping automatically when display is off
```

**⚠️ Important**: If your Mac goes to sleep, you'll lose connection to Claude Code. Use `caffeinate` or adjust energy settings.

### While Out of the House

#### 5. **Using Your iPhone**
1. **Open the iOS Shortcut** you created
2. **Dictate your message** (e.g., "Help me debug this Python function")
3. **Watch for response** - the shortcut will poll and show Claude's reply
4. **Continue the conversation** by running the shortcut again

#### 6. **What Happens Behind the Scenes**
```
Your Voice → iPhone Shortcut → Tailscale → Your Mac → Bridge Server → tmux → Claude Code
                                                                                    ↓
Your iPhone ← Tailscale ← Your Mac ← Bridge Server ← tmux ← Claude Code Response
```

### When You Return Home

#### 7. **Check What Happened**
```bash
# Reattach to see the full conversation
tmux attach -t claude

# Review the session history
# You'll see all the messages you sent and Claude's responses

# Detach when done
# Press: Ctrl+B, then D
```

## 🚀 Usage

### Complete Workflow

1. **Setup** (one-time): Install and configure the bridge server
2. **Start Claude Code** (before leaving): `tmux attach -t claude && cd ~/Documents/Code && claude`
3. **Use from iPhone**: Tap shortcut → dictate message → view live response
4. **Continue conversation**: Send more messages as needed

### How It Works

When you send a message from your iPhone:

1. **Voice input** → iOS Shortcut captures your dictated text
2. **HTTP POST** → Sends message to bridge server via Tailscale
3. **tmux injection** → Bridge sends text directly to Claude Code
4. **Auto-submit** → Message is automatically submitted with Enter key
5. **Live view** → Opens mobile-optimized web interface to see responses
6. **Real-time updates** → Refresh to see new responses as they're generated

### Example Usage

```
You: "Help me debug this Python function that's not working"
Claude: [Analyzes code, provides debugging steps, suggests fixes]

You: "Can you also add error handling to it?"
Claude: [Adds try-catch blocks, explains error handling best practices]

You: "Perfect! Now can you write tests for it?"
Claude: [Creates comprehensive unit tests with edge cases]
```

### Manual Testing

```bash
# Test locally
TOKEN=$(cat ~/.claude-bridge/token.txt)
curl -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"text":"Hello Claude! Can you help me with some coding?"}' \
     http://127.0.0.1:8008/send

# Test from iPhone (replace with your actual URL)
curl -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"text":"What files are in the current directory?"}' \
     https://your-mac.your-tailnet.ts.net/send
```

## 🔒 Security Features

- **Private Access Only**: Default tailnet-only access
- **Bearer Token Authentication**: Secure API access
- **HTTPS Encryption**: Managed certificates via Tailscale
- **No Shell Execution**: Messages only sent to Claude Code
- **Request Logging**: All requests logged with timestamps

## 📊 API Endpoints

### POST /send
Send a message to Claude Code.

**Request:**
```json
{
  "text": "Your message to Claude here",
  "id": "optional-custom-id",
  "mode": "ask",
  "workdir": "optional-working-directory",
  "wait_ms": 1500
}
```

**Response:**
```json
{
  "id": "generated-job-id",
  "status": "accepted",
  "preview": "First 2000 chars of Claude's response..."
}
```

### GET /jobs/{id}/tail
Get the latest output for a job.

**Parameters:**
- `id`: Job ID from /send response
- `lines`: Number of lines to return (default: 400)

**Response:** Plain text output

### GET /jobs/{id}/live
Live updating HTML view of the job (no authentication required).

**Features:**
- **Manual refresh button** - No auto-refresh, you control when to update
- **Auto-scroll to bottom** - Always shows the newest content
- **Sticky header** - Refresh button always accessible while scrolling
- **Mobile-optimized** - Full-screen layout with edge-to-edge content
- **Beautiful dark theme** - Easy on the eyes with monospace font
- **Real-time content** - Captures fresh tmux content on each refresh

**Response:** HTML page with live-updating content

### GET /healthz
Health check endpoint (no authentication required).

**Response:**
```json
{
  "ok": true,
  "tmux_target": "claude:0.0"
}
```

## 🔍 Debugging Failed Queries

### Quick Diagnostic Steps

When your iPhone shortcuts aren't working, follow these steps to identify the problem:

#### 1. **Check Your iPhone Shortcut Response**
- **Success**: `{"id":"abc123","status":"accepted","preview":"..."}`
- **Auth Error**: `{"error":"unauthorized"}` → Check your bearer token
- **Not Found**: `{"detail":"Not Found"}` → Bridge server down or wrong URL
- **Network Error**: Connection timeout → Tailscale or Mac sleep issue

#### 2. **Quick Health Check from iPhone**
```bash
# Test this URL in Safari on your iPhone:
https://your-mac.your-tailnet.ts.net/healthz

# Should show: {"ok":true,"tmux_target":"claude:0.0"}
# If it fails: Mac is asleep or Tailscale is down
```

#### 3. **Systematic Diagnosis Process**

**Step A: Is your Mac reachable?**
```bash
# From your iPhone, try accessing:
https://your-mac.your-tailnet.ts.net/healthz

❌ Fails? → Mac is asleep or Tailscale issue
✅ Works? → Continue to Step B
```

**Step B: Is the bridge server running?**
```bash
# SSH to your Mac or check when you get home:
ps aux | grep claude_bridge_server

❌ No process? → Bridge server crashed
✅ Running? → Continue to Step C
```

**Step C: Is Claude Code active in tmux?**
```bash
# Check tmux session:
tmux list-sessions | grep claude
tmux capture-pane -t claude:0.0 -p | tail -5

❌ No session or no Claude? → Claude Code not running
✅ Claude active? → Continue to Step D
```

**Step D: Check the logs**
```bash
# Bridge server logs:
tail -20 ~/.claude-bridge/logs/bridge.log

# Look for recent entries when you tried to send messages
```

### Common Failure Patterns

#### Pattern 1: "Connection Failed" on iPhone
**Symptoms**: Shortcut shows network error, can't reach server
**Cause**: Mac went to sleep or Tailscale disconnected
**Fix**:
```bash
# Wake up Mac, then:
tailscale status  # Check if connected
tailscale up      # Reconnect if needed
caffeinate -d &   # Prevent future sleep
```

#### Pattern 2: "Unauthorized" Error
**Symptoms**: `{"error":"unauthorized"}` response
**Cause**: Wrong bearer token in iOS Shortcut
**Fix**:
```bash
# Get the correct token:
cat ~/.claude-bridge/token.txt

# Update your iOS Shortcut with this exact token
# Format: "Bearer YOUR_TOKEN_HERE"
```

#### Pattern 3: Messages Send But Claude Doesn't Respond
**Symptoms**: Shortcut succeeds but no Claude response
**Cause**: Claude Code not running or crashed
**Fix**:
```bash
# Check tmux session:
tmux attach -t claude

# If Claude crashed, restart it:
claude

# Detach: Ctrl+B, then D
```

#### Pattern 4: Bridge Server Stopped Working
**Symptoms**: /healthz fails, "service unavailable"
**Cause**: Bridge server process died
**Fix**:
```bash
# Restart bridge server:
cd ~ && source ~/.claude-bridge/venv/bin/activate
nohup python ~/bin/claude_bridge_server.py > ~/.claude-bridge/logs/bridge.log 2>&1 &
```

#### Pattern 5: iOS Shortcut Polling Errors
**Symptoms**: `{"detail":[{"loc":["body"],"type":"missing","msg":"Field required","input":null}]}`
**Cause**: GET request for polling accidentally includes request body
**Fix**: In your iOS Shortcut Action 7 (polling GET request):
- Ensure Method is `GET`
- Ensure "Request Body" is `None` or empty
- Only the initial `/send` POST should have a request body

### Remote Debugging Tools

#### 1. **Status Check Script** (run this when you get home)
```bash
# Create a quick diagnostic script:
echo '#!/bin/bash
echo "=== CLAUDE BRIDGE DIAGNOSTICS ==="
echo "Bridge Server Status:"
ps aux | grep claude_bridge_server | grep -v grep || echo "❌ Bridge server not running"
echo ""
echo "tmux Session Status:"
tmux list-sessions | grep claude || echo "❌ No claude tmux session"
echo ""
echo "Tailscale Status:"
tailscale status | head -3
echo ""
echo "Recent Bridge Logs:"
tail -10 ~/.claude-bridge/logs/bridge.log
' > ~/debug-claude-bridge.sh && chmod +x ~/debug-claude-bridge.sh

# Run anytime: ./debug-claude-bridge.sh
```

#### 2. **From Your Phone: Test URLs**
When shortcuts fail, test these URLs directly in Safari:

```
1. https://your-mac.your-tailnet.ts.net/healthz

   ✅ Works → Mac and bridge are up
   ❌ Fails → Mac asleep or Tailscale down

2. https://your-mac.your-tailnet.ts.net/send
   (Will show "Method Not Allowed" - this is expected)
   ✅ Shows error page → Bridge server responding
   ❌ Can't connect → Bridge server down
```

#### 3. **Proactive Monitoring**
```bash
# Set up a simple monitoring loop (run before leaving):
while true; do
  if curl -s http://localhost:8008/healthz > /dev/null; then
    echo "$(date): Bridge healthy ✅"
  else
    echo "$(date): Bridge DOWN ❌" 
    # Auto-restart bridge:
    cd ~ && source ~/.claude-bridge/venv/bin/activate
    nohup python ~/bin/claude_bridge_server.py > ~/.claude-bridge/logs/bridge.log 2>&1 &
  fi
  sleep 300  # Check every 5 minutes
done &
```

## 🐛 Troubleshooting

### Common Issues

#### Bridge Server Not Running
```bash
# Check status
ps aux | grep claude_bridge_server

# Start manually
cd ~ && source ~/.claude-bridge/venv/bin/activate && nohup python ~/bin/claude_bridge_server.py > ~/.claude-bridge/logs/bridge.log 2>&1 &
```

#### tmux Session Issues
```bash
# Check tmux sessions
tmux list-sessions

# Recreate if needed
tmux kill-session -t claude
tmux new -s claude -d
```

#### Tailscale Connection Issues
```bash
# Check Tailscale status
tailscale status

# Restart Tailscale
tailscale down && tailscale up

# Check serve status
tailscale serve status
```

#### Authentication Errors
```bash
# Verify token
cat ~/.claude-bridge/token.txt

# Check token format in iOS Shortcut
# Should be: "Bearer YOUR_TOKEN_HERE"
```

#### Claude Code Not Starting
```bash
# Check if Claude is installed
which claude

# Test Claude manually
claude

# Check tmux session
tmux capture-pane -t claude:0.0 -p | tail -20
```

#### Text Not Being Submitted
```bash
# Ensure Claude Code is running in tmux
tmux attach -t claude

# Check if you're in the right directory
pwd  # Should show ~/Documents/Code

# Verify Claude is active
# Should see "Welcome to Claude Code!" message
```

### Logs

- **Bridge Server**: `~/.claude-bridge/logs/bridge.log`
- **Bridge Output**: Check with `ps aux | grep claude_bridge_server`

## 🔄 Maintenance

### Token Rotation
```bash
# Generate new token
openssl rand -hex 32 > ~/.claude-bridge/token.txt

# Update iOS Shortcut with new token
# No server restart needed
```

### Updates
```bash
# Update Tailscale
brew upgrade tailscale

# Update Python dependencies
source ~/.claude-bridge/venv/bin/activate
uv pip install --upgrade fastapi uvicorn pydantic
```

### Monitoring
```bash
# Check system health
curl -s http://127.0.0.1:8008/healthz

# Monitor logs
tail -f ~/.claude-bridge/logs/bridge.log

# Check Tailscale status
tailscale status
tailscale serve status
```

## 🌐 Public Access (Optional)

If you need public internet access:

```bash
# Enable Funnel (public HTTPS)
tailscale funnel 443 on

# Check status
tailscale funnel status

# Disable when not needed
tailscale funnel 443 off
```

**Warning**: Public access requires strong authentication and careful security consideration.

## 📚 File Structure

```
.
├── README.md                           # This comprehensive guide
├── claude_bridge_server.py            # FastAPI server (symlinked to ~/bin/)
├── .gitignore                         # Git ignore patterns
├── claude-bridge.env.template         # Environment variables template
├── com.user.claude-bridge.plist.template # LaunchAgent template
├── setup.sh                           # Main setup script
├── start-bridge.sh                    # Start bridge server
├── status.sh                          # System status checker
├── test-bridge.sh                     # Test bridge functionality
├── demo.sh                            # Demo script
├── debug-claude-bridge.sh             # Diagnostic script
├── quick-start.sh                     # Quick setup script
├── tailscale-setup.sh                 # Tailscale configuration
└── ios-shortcut-guide.md              # Detailed iOS Shortcut setup guide
```

**Key Files:**
- **`claude_bridge_server.py`** - The main FastAPI server with live view interface
- **`claude-bridge.env.template`** - Environment configuration template
- **`setup.sh`** - Automated setup script that creates user-specific configs
- **`README.md`** - Complete setup and usage guide
- **`debug-claude-bridge.sh`** - Quick diagnostic tool for troubleshooting

## 🤝 Contributing

This project is open source and welcomes contributions! Areas for improvement:

- **Mobile UI enhancements** - Better responsive design, gestures, themes
- **Authentication improvements** - OAuth, multiple users, session management  
- **Performance optimizations** - Faster response times, better memory usage
- **Additional integrations** - Support for other AI coding assistants
- **Documentation** - Better guides, video tutorials, troubleshooting

### Development Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-bridge.git
cd claude-bridge

# Set up development environment
python -m venv venv
source venv/bin/activate
pip install fastapi uvicorn pydantic

# Run in development mode
python claude_bridge_server.py
```

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- **Tailscale** for secure, zero-config networking
- **FastAPI** for the modern, fast web framework
- **tmux** for reliable terminal session management
- **Claude Code** for the AI-powered development environment
- **iOS Shortcuts** for seamless mobile integration

## ⭐ Star This Project

If this project helps you continue coding while on the go, please give it a star! ⭐

---

**Happy remote coding with Claude! 🚀**
