#!/bin/bash

# Start Claude Bridge Server
# This script starts the bridge server in the background

# Load environment variables
if [ -f ~/.claude-bridge/.env ]; then
    source ~/.claude-bridge/.env
fi

# Set defaults if not in env
PORT=${PORT:-8008}
HOST=${HOST:-127.0.0.1}
VENV_PATH=${VENV_PATH:-$HOME/.venvs/claude-bridge}
BIN_DIR=${BIN_DIR:-$HOME/bin}
LOG_DIR=${LOG_DIR:-$HOME/.claude-bridge/logs}

echo "🚀 Starting Claude Bridge Server..."

# Check if bridge is already running
if curl -s http://$HOST:$PORT/healthz > /dev/null 2>&1; then
    echo "✅ Bridge server is already running on $HOST:$PORT"
    echo "🔍 Health check:"
    curl -s http://$HOST:$PORT/healthz | jq . 2>/dev/null || curl -s http://$HOST:$PORT/healthz
    exit 0
fi

# Activate virtual environment and start server
echo "📦 Activating Python environment..."
source "$VENV_PATH/bin/activate"

echo "🌐 Starting server on $HOST:$PORT..."
cd "$BIN_DIR"
nohup python3 claude_bridge_server.py > "$LOG_DIR/server.log" 2>&1 &

# Wait for server to start
echo "⏳ Waiting for server to start..."
sleep 3

# Test the server
if curl -s http://$HOST:$PORT/healthz > /dev/null 2>&1; then
    echo "✅ Bridge server started successfully!"
    echo "🔍 Health check:"
    curl -s http://$HOST:$PORT/healthz | jq . 2>/dev/null || curl -s http://$HOST:$PORT/healthz
    echo ""
    echo "🌐 Server running on: http://$HOST:$PORT"
    echo "📱 Next: Run 'tailscale serve --https=443 --bg localhost:$PORT' to expose to iPhone"
else
    echo "❌ Failed to start bridge server"
    echo "📋 Check logs: tail -f $LOG_DIR/server.log"
    exit 1
fi
