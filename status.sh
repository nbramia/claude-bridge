#!/bin/bash

# Status Checker for Claude Bridge
# This script provides a quick overview of system health

echo "🔍 Claude Bridge System Status"
echo "=============================="
echo ""

# Check bridge server
echo "🌐 Bridge Server:"
if curl -s http://127.0.0.1:8008/healthz > /dev/null; then
    HEALTH=$(curl -s http://127.0.0.1:8008/healthz)
    echo "✅ Running - $(echo $HEALTH | grep -o '"ok":[^,]*' | cut -d':' -f2)"
    echo "   Target: $(echo $HEALTH | grep -o '"tmux_target":"[^"]*"' | cut -d'"' -f4)"
else
    echo "❌ Not running"
fi
echo ""

# Check tmux session
echo "📺 Tmux Session:"
if tmux has-session -t claude 2>/dev/null; then
    echo "✅ Session 'claude' exists"
    PANES=$(tmux list-panes -t claude 2>/dev/null | wc -l)
    echo "   Panes: $PANES"
else
    echo "❌ Session 'claude' not found"
fi
echo ""

# Check LaunchAgent
echo "🚀 LaunchAgent:"
if launchctl list | grep -q claude-bridge; then
    echo "✅ Loaded: com.nathan.claude-bridge"
else
    echo "❌ Not loaded"
fi
echo ""

# Check Tailscale
echo "🔗 Tailscale:"
if command -v tailscale &> /dev/null; then
    if tailscale status &> /dev/null; then
        echo "✅ Running"
        SERVE_STATUS=$(tailscale serve status 2>/dev/null || echo "No serve config")
        echo "   Serve: $SERVE_STATUS"
    else
        echo "❌ Not running"
    fi
else
    echo "❌ Not installed"
fi
echo ""

# Check authentication
echo "🔐 Authentication:"
if [ -f ~/.claude-bridge/token.txt ]; then
    TOKEN=$(cat ~/.claude-bridge/token.txt)
    echo "✅ Token exists: ${TOKEN:0:8}..."
else
    echo "❌ No token found"
fi
echo ""

# Check logs
echo "📋 Logs:"
if [ -f ~/.claude-bridge/logs/bridge.log ]; then
    LOG_SIZE=$(ls -lh ~/.claude-bridge/logs/bridge.log | awk '{print $5}')
    echo "✅ Bridge log: $LOG_SIZE"
    echo "   Recent entries:"
    tail -3 ~/.claude-bridge/logs/bridge.log 2>/dev/null | sed 's/^/   /'
else
    echo "❌ No bridge log found"
fi
echo ""

# Check environment
echo "⚙️ Configuration:"
if [ -f ~/.claude-bridge/.env ]; then
    echo "✅ Environment file exists"
    echo "   Port: $(grep '^PORT=' ~/.claude-bridge/.env | cut -d'=' -f2)"
    echo "   Max lines: $(grep '^MAX_CAPTURE_LINES=' ~/.claude-bridge/.env | cut -d'=' -f2)"
else
    echo "❌ No environment file found"
fi
echo ""

echo "📱 To use from iPhone:"
echo "   1. Ensure Tailscale is running on both devices"
echo "   2. Run: tailscale serve --https=443 --bg localhost:8008"
echo "   3. Create iOS Shortcut using ios-shortcut-guide.md"
echo ""
echo "🧪 Test locally: ./demo.sh"
echo "🔧 Full test: ./test-bridge.sh"
