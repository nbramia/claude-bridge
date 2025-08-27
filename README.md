# Claude Bridge - Remote Control for Claude Code

A secure, private system that allows you to control Claude Code on your Mac from your iPhone using Tailscale. Perfect for developers who want to continue coding while on the go.

## 🚀 Features

- **Secure Remote Access**: Private tailnet-only access using Tailscale
- **Voice Commands**: Dictate messages from your iPhone to Claude Code
- **Real-time Updates**: Poll for responses and see live Claude Code output
- **No Public Exposure**: Secure by default, HTTPS with managed certificates
- **Automatic Startup**: Runs as a background service, survives reboots
- **tmux Integration**: Robust command injection and output capture
- **Reliable Text Submission**: Clean, focused interaction with Claude Code

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
# Navigate to your workspace
cd /path/to/your/workspace

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
# Make bridge accessible from iPhone
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

Follow the detailed guide in [ios-shortcut-guide.md](ios-shortcut-guide.md) to create your remote control shortcut.

## 🔧 Configuration

### Environment Variables

The bridge server is configured via `~/.claude-bridge/.env`:

```bash
PORT=8008                           # Local port for the bridge
TMUX_TARGET=claude:0.0             # tmux session and pane
MAX_CAPTURE_LINES=2000             # Max lines to capture
CAPTURE_DELAY_MS=1500              # Wait time after sending command
BEARER_TOKEN_FILE=/path/to/token   # Authentication token
LOG_FILE=/path/to/logs             # Log file location
```

### Authentication

Your authentication token is automatically generated and stored in `~/.claude-bridge/token.txt`. This token is required for all API requests.

## 🚀 Usage

### Starting Claude Code

```bash
# Attach to the tmux session
tmux attach -t claude

# Manually start Claude Code in the right directory:
cd ~/Documents/Code
claude

# Detach (Ctrl+B, then D)
```

**Important**: Claude Code must be manually started in `~/Documents/Code` before using the bridge. The bridge will not automatically navigate or start Claude Code.

### Sending Messages from iPhone

1. **Tap the Shortcut** on your iPhone
2. **Dictate your message** (e.g., "Can you help me refactor this Python function?")
3. **Wait for response** - the shortcut polls for updates
4. **View Claude's response** in Quick Look
5. **Continue or stop** polling as needed

### How It Works

When you send a message from your iPhone:

1. **Bridge server receives** your text message
2. **Sends marker** to the shell for tracking
3. **Sends your message** directly to Claude Code
4. **Automatically submits** the message with Enter key
5. **Captures Claude's response** and returns it to your iPhone

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

### GET /healthz
Health check endpoint (no authentication required).

**Response:**
```json
{
  "ok": true,
  "tmux_target": "claude:0.0"
}
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
├── README.md                    # This file
├── setup.sh                     # Main installation script
├── tailscale-setup.sh          # Tailscale configuration
├── test-bridge.sh              # Testing and verification
├── claude_bridge_server.py     # FastAPI server
├── claude-bridge.env           # Environment template
├── com.nathan.claude-bridge.plist  # LaunchAgent configuration
├── ios-shortcut-guide.md       # iOS Shortcut setup guide
├── quick-start.sh              # One-command setup
├── demo.sh                     # Live demonstration
└── status.sh                   # System health monitoring
```

## 🤝 Contributing

This is a personal project, but suggestions and improvements are welcome. The system is designed to be:

- **Secure by default**
- **Easy to deploy**
- **Reliable in operation**
- **Simple to maintain**

## 📄 License

This project is provided as-is for personal use. Tailscale and other components have their own licenses.

## 🙏 Acknowledgments

- **Tailscale** for secure networking
- **FastAPI** for the web framework
- **tmux** for reliable terminal management
- **Claude Code** for the AI-powered development environment

---

**Happy remote coding with Claude! 🚀**
