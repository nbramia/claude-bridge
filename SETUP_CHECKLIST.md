# Setup Checklist for Claude Bridge

This checklist clearly shows what gets automated vs. what you need to do manually.

## ✅ **AUTOMATED by Scripts** (No manual work needed)

- [x] Install Homebrew packages (tmux, uv, tailscale CLI)
- [x] Create Python virtual environment
- [x] Install Python dependencies (FastAPI, uvicorn, pydantic)
- [x] Generate authentication token
- [x] Create configuration files
- [x] Set up LaunchAgent for auto-start
- [x] Create tmux session
- [x] Test local bridge functionality
- [x] Configure Tailscale CLI settings

## ⚠️ **MANUAL Steps Required** (Cannot be automated)

### 1. Tailscale Account & Setup
- [ ] Go to [tailscale.com](https://tailscale.com)
- [ ] Create free account (Google/GitHub login)
- [ ] Note your tailnet name (e.g., `your-tailnet.ts.net`)

### 2. Install Tailscale Apps
- [ ] **Mac**: Download from [tailscale.com/download](https://tailscale.com/download) or `brew install tailscale`
- [ ] **iPhone**: Install from App Store
- [ ] Sign in to both apps with same account

### 3. Enable MagicDNS
- [ ] Go to [login.tailscale.com/admin/dns](https://login.tailscale.com/admin/dns)
- [ ] Enable MagicDNS for your tailnet
- [ ] This allows `your-mac.your-tailnet.ts.net` URLs

### 4. Expose Bridge to iPhone
- [ ] Run: `tailscale serve --https=443 --bg localhost:8008`
- [ ] Verify: `tailscale serve status`

### 5. Create iOS Shortcut
- [ ] Follow [ios-shortcut-guide.md](ios-shortcut-guide.md)
- [ ] Use your authentication token from `~/.claude-bridge/token.txt`
- [ ] Configure with your actual Mac hostname and tailnet name

## 🚀 **Quick Start Workflow**

```bash
# 1. Complete manual steps 1-3 above FIRST
# 2. Run automated setup
./quick-start.sh

# 3. Complete manual steps 4-5 above
# 4. Test from iPhone!
```

## 🔍 **Verification Commands**

```bash
# Check system health
./status.sh

# Test bridge locally
./demo.sh

# Check Tailscale
tailscale status
tailscale serve status

# Test from iPhone (replace with your URL)
curl https://your-mac.your-tailnet.ts.net/healthz
```

## ❓ **Common Questions**

**Q: Why can't the scripts create my Tailscale account?**
A: Tailscale accounts require web browser interaction and cannot be created via CLI.

**Q: Why can't the scripts install the iPhone app?**
A: iOS app installation requires the App Store and cannot be automated from a Mac.

**Q: Why can't the scripts create the iOS Shortcut?**
A: iOS Shortcuts require manual setup in the Shortcuts app and cannot be created remotely.

**Q: What happens if I skip the manual steps?**
A: The bridge will work locally but won't be accessible from your iPhone, defeating the purpose.

## 🎯 **Success Criteria**

You're ready to use Claude Bridge when:
- [ ] Bridge responds to `curl http://127.0.0.1:8008/healthz`
- [ ] `tailscale serve status` shows your bridge
- [ ] iPhone can reach `https://your-mac.your-tailnet.ts.net/healthz`
- [ ] iOS Shortcut successfully sends commands and receives responses
