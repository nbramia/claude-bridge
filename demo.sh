#!/bin/bash

# Demo Script for Claude Bridge
# This script demonstrates the bridge functionality

set -e

echo "🎭 Claude Bridge Demo"
echo "===================="
echo ""

# Check if bridge is running
echo "🔍 Checking bridge status..."
if ! curl -s http://127.0.0.1:8008/healthz > /dev/null; then
    echo "❌ Bridge server is not running. Please run setup first."
    exit 1
fi

echo "✅ Bridge server is running"
echo ""

# Get authentication token
TOKEN=$(cat ~/.claude-bridge/token.txt 2>/dev/null || echo "NO_TOKEN")
if [ "$TOKEN" = "NO_TOKEN" ]; then
    echo "❌ No authentication token found. Please run setup first."
    exit 1
fi

echo "🔑 Using authentication token: ${TOKEN:0:8}..."
echo ""

# Demo 1: Simple command
echo "📝 Demo 1: Simple command"
echo "Sending: echo 'Hello from Claude Bridge'"
RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"text":"echo \"Hello from Claude Bridge\""}' \
    http://127.0.0.1:8008/send)

JOB_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "✅ Command sent. Job ID: $JOB_ID"
echo ""

# Wait a moment for processing
echo "⏳ Waiting for response..."
sleep 3

# Get the response
echo "📤 Getting response..."
TAIL_RESPONSE=$(curl -s "http://127.0.0.1:8008/jobs/$JOB_ID/tail?lines=10")
echo "Response:"
echo "$TAIL_RESPONSE"
echo ""

# Demo 2: Directory listing
echo "📝 Demo 2: Directory listing"
echo "Sending: ls -la"
RESPONSE2=$(curl -s -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"text":"ls -la"}' \
    http://127.0.0.1:8008/send)

JOB_ID2=$(echo "$RESPONSE2" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "✅ Command sent. Job ID: $JOB_ID2"
echo ""

# Wait for processing
echo "⏳ Waiting for response..."
sleep 3

# Get the response
echo "📤 Getting response..."
TAIL_RESPONSE2=$(curl -s "http://127.0.0.1:8008/jobs/$JOB_ID2/tail?lines=15")
echo "Response:"
echo "$TAIL_RESPONSE2"
echo ""

# Demo 3: Show available endpoints
echo "📝 Demo 3: Available endpoints"
echo "Health check:"
curl -s http://127.0.0.1:8008/healthz | jq . 2>/dev/null || curl -s http://127.0.0.1:8008/healthz
echo ""

echo "🎉 Demo complete!"
echo ""
echo "💡 This demonstrates how your iPhone can send commands to Claude Code"
echo "   and receive responses in real-time."
echo ""
echo "📱 Next: Set up the iOS Shortcut using ios-shortcut-guide.md"
echo "🌐 Then expose via Tailscale: tailscale serve --https=443 --bg localhost:8008"
