#!/bin/bash

# Tailscale Setup Script for Claude Bridge
# This script helps configure Tailscale to expose the Claude bridge

set -e

echo "🔗 Setting up Tailscale for Claude Bridge..."

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    echo "📦 Installing Tailscale..."
    brew install tailscale
else
    echo "✅ Tailscale is already installed"
fi

# Check if Tailscale is running
if ! tailscale status &> /dev/null; then
    echo "🚀 Starting Tailscale..."
    tailscale up
else
    echo "✅ Tailscale is already running"
fi

echo "🔍 Checking Tailscale status..."
tailscale status

echo ""
echo "📱 Next steps:"
echo "   1. Install Tailscale on your iPhone from the App Store"
echo "   2. Sign in with the same account on both devices"
echo "   3. Enable MagicDNS in the Tailscale admin console (https://login.tailscale.com/admin/dns)"
echo "   4. Make sure both devices are connected to the same tailnet"
echo ""
echo "🔒 Once both devices are connected, run this command to expose the bridge:"
echo "   tailscale serve --https=443 --bg localhost:8008"
echo ""
echo "🌐 Your bridge will then be available at:"
echo "   https://$(hostname).$(tailscale status --json | grep -o '"TailnetName":"[^"]*"' | cut -d'"' -f4).ts.net"
echo ""
echo "🧪 Test the connection from your iPhone by visiting:"
echo "   https://$(hostname).$(tailscale status --json | grep -o '"TailnetName":"[^"]*"' | cut -d'"' -f4).ts.net/healthz"
