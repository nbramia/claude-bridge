#!/bin/bash

# Quick Start Script for Claude Bridge
# This script runs the essential setup steps in sequence

set -e

echo "🚀 Quick Start: Claude Bridge Setup"
echo "=================================="
echo ""

echo "⚠️  IMPORTANT: Before running this script, you MUST:"
echo "   1. Create a Tailscale account at tailscale.com"
echo "   2. Install Tailscale on your iPhone from the App Store"
echo "   3. Sign in to both Mac and iPhone with the same account"
echo "   4. Enable MagicDNS in your Tailscale admin console"
echo ""

read -p "Have you completed the manual Tailscale setup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Please complete the manual Tailscale setup first, then run this script again."
    echo ""
    echo "📋 Manual steps:"
    echo "   • Go to tailscale.com and create account"
    echo "   • Install Tailscale app on iPhone"
    echo "   • Sign in to both devices"
    echo "   • Enable MagicDNS at login.tailscale.com/admin/dns"
    exit 1
fi

echo "✅ Great! Let's proceed with the automated setup..."
echo ""

# Step 1: Run main setup
echo "📦 Step 1: Installing dependencies and setting up bridge..."
./setup.sh

echo ""
echo "⏳ Waiting for bridge server to start..."
sleep 5

# Step 2: Test the bridge
echo ""
echo "🧪 Step 2: Testing bridge functionality..."
./test-bridge.sh

# Step 3: Tailscale setup
echo ""
echo "🔗 Step 3: Setting up Tailscale..."
./tailscale-setup.sh

echo ""
echo "🎉 Automated setup complete!"
echo ""
echo "📱 Next steps (manual):"
echo "   1. ✅ Install Tailscale on iPhone (already done)"
echo "   2. ✅ Sign in with same account (already done)"
echo "   3. ✅ Enable MagicDNS (already done)"
echo "   4. 🔄 Run: tailscale serve --https=443 --bg localhost:8008"
echo "   5. 📱 Create iOS Shortcut using the guide in ios-shortcut-guide.md"
echo ""
echo "🔑 Your authentication token:"
cat ~/.claude-bridge/token.txt
echo ""
echo "🌐 Test locally: curl -s http://127.0.0.1:8008/healthz"
echo ""
echo "💡 Use './status.sh' to check system health anytime"
