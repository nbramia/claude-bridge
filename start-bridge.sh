#!/bin/bash

# Start Claude Bridge Server
# This script starts the bridge server in the background

echo "🚀 Starting Claude Bridge Server..."

# Check if bridge is already running
if curl -s http://127.0.0.1:8008/healthz > /dev/null 2>&1; then
    echo "✅ Bridge server is already running on port 8008"
    echo "🔍 Health check:"
    curl -s http://127.0.0.1:8008/healthz | jq . 2>/dev/null || curl -s http://127.0.0.1:8008/healthz
    exit 0
fi

# Activate virtual environment and start server
echo "📦 Activating Python environment..."
source ~/.venvs/claude-bridge/bin/activate

echo "🌐 Starting server on port 8008..."
cd ~/bin
nohup python3 claude_bridge_server.py > ~/.claude-bridge/logs/server.log 2>&1 &

# Wait for server to start
echo "⏳ Waiting for server to start..."
sleep 3

# Test the server
if curl -s http://127.0.0.1:8008/healthz > /dev/null 2>&1; then
    echo "✅ Bridge server started successfully!"
    echo "🔍 Health check:"
    curl -s http://127.0.0.1:8008/healthz | jq . 2>/dev/null || curl -s http://127.0.0.1:8008/healthz
    echo ""
    echo "🌐 Server running on: http://127.0.0.1:8008"
    echo "📱 Next: Run 'tailscale serve --https=443 --bg localhost:8008' to expose to iPhone"
else
    echo "❌ Failed to start bridge server"
    echo "📋 Check logs: tail -f ~/.claude-bridge/logs/server.log"
    exit 1
fi
