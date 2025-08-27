#!/bin/bash

# Test Script for Claude Bridge
# This script tests the bridge server functionality

set -e

echo "🧪 Testing Claude Bridge..."

# Check if the bridge server is running
echo "🔍 Checking if bridge server is running..."
if curl -s http://127.0.0.1:8008/healthz > /dev/null; then
    echo "✅ Bridge server is running"
else
    echo "❌ Bridge server is not running. Starting it..."
    launchctl start com.nathan.claude-bridge
    sleep 3
fi

# Test health endpoint
echo "🔍 Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s http://127.0.0.1:8008/healthz)
echo "Health response: $HEALTH_RESPONSE"

# Check tmux session
echo "🔍 Checking tmux session..."
if tmux has-session -t claude 2>/dev/null; then
    echo "✅ Tmux session 'claude' exists"
    TMUX_STATUS=$(tmux list-panes -t claude 2>/dev/null || echo "No panes")
    echo "Tmux panes: $TMUX_STATUS"
else
    echo "❌ Tmux session 'claude' does not exist"
    echo "Creating it now..."
    tmux new -s claude -d
    echo "✅ Created tmux session 'claude'"
fi

# Test authentication
echo "🔍 Testing authentication..."
TOKEN=$(cat ~/.claude-bridge/token.txt 2>/dev/null || echo "NO_TOKEN")
if [ "$TOKEN" = "NO_TOKEN" ]; then
    echo "❌ No authentication token found"
    exit 1
fi

# Test send endpoint (if tmux is working)
if tmux has-session -t claude 2>/dev/null; then
    echo "🔍 Testing send endpoint..."
    TEST_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"text":"echo Hello from bridge test"}' \
        http://127.0.0.1:8008/send)
    echo "Send response: $TEST_RESPONSE"
    
    # Extract job ID and test tail endpoint
    JOB_ID=$(echo "$TEST_RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$JOB_ID" ]; then
        echo "🔍 Testing tail endpoint for job $JOB_ID..."
        sleep 2
        TAIL_RESPONSE=$(curl -s "http://127.0.0.1:8008/jobs/$JOB_ID/tail?lines=10")
        echo "Tail response (first 200 chars): ${TAIL_RESPONSE:0:200}..."
    fi
fi

echo ""
echo "✅ Bridge test complete!"
echo "🔑 Your authentication token: $TOKEN"
echo "🌐 Local bridge URL: http://127.0.0.1:8008"
echo ""
echo "📱 To test from iPhone:"
echo "   1. Make sure Tailscale is set up and both devices are connected"
echo "   2. Run: tailscale serve --https=443 --bg localhost:8008"
echo "   3. Test from iPhone browser or create iOS Shortcut"
