# iOS Shortcut Setup Guide for Claude Bridge

This guide will help you create an iOS Shortcut that allows you to control Claude Code on your Mac from your iPhone.

## Prerequisites

1. ✅ Claude Bridge server running on your Mac
2. ✅ Tailscale installed and configured on both Mac and iPhone
3. ✅ Bridge server exposed via `tailscale serve --https=443 --bg localhost:8008`
4. ✅ Your authentication token from `~/.claude-bridge/token.txt`

## Step-by-Step Shortcut Creation

### 1. Create New Shortcut
- Open the **Shortcuts** app on your iPhone
- Tap the **+** button to create a new shortcut
- Name it "Send to Claude"

### 2. Add Actions

#### Action 1: Dictate Text
- Add the action
- Configure:
  - Language: Your preferred language
  - Stop Listening: After pause (or your preference)

OR 

#### Action 1: Ask for Input
- Add the action
- Configure:
  - wih: What do you want to send Claude?
  - Default Answer: blank
  - Allow multiple lines

#### Action 2: Get Contents of URL (POST)
- Add the action
- Configure:
  - URL: `https://[YOUR-DEVICE].[YOUR-TAILNET].ts.net/send`
  - Method: `POST`
  - Headers: Add new header
    - Add entry
      - Key: `Authorization`
      - Value: `Bearer YOUR_TOKEN_HERE`
    - Add another entry:
      - Key: `text`
      - Value: `Dictated Text` or `Ask for Input` (from previous action)

#### Action 3: Get Dictionary from Input
- Add the action
- Configure:
  - Input: `Contents of URL` (from previous action)

#### Action 4: Get Dictionary Value
- Add the action
- Configure:
  - Input: `Dictionary` (from previous action)
  - Key: `id`

#### Action 5: Text (URL Construction)
- Add the action
- Configure:
  - Text: `https://[YOUR-DEVICE].[YOUR-TAILNET].ts.net/jobs/`[Dictionary Value]`/live`
  - Note: "Dictionary Value" will be highlighted in orange, indicating it's a variable

#### Action 6: Open URL in Chrome (or another browser)
- Add the action
- Configure:
  - Input: `Text` (from previous action)

#### Action 7: Stop this Shortcut 
- Add the action

## Configuration Notes

### Replace Placeholders
- `YOUR-DEVICE`: Your device's hostname on Tailnet
- `YOUR-TAILNET`: Your Tailscale tailnet name
- `YOUR_TOKEN_HERE`: Your authentication token from `~/.claude-bridge/token.txt`

### How the ID System Works
1. **Send command** to `/send` endpoint → gets response with `{"id": "abc123", ...}`
2. **"Get dictionary from"** action extracts the response
3. **"Get Dictionary Value"** action extracts just the `id` field (e.g., "abc123")
4. **"Text"** action constructs URL using the extracted `id` value
5. **"Get contents of URL"** uses the constructed URL to fetch the job output

**Note**: You must extract the `id` value using "Get Dictionary Value" before constructing the URL. The `Dictionary` variable contains the entire response, not just the ID.

### Example URL
If your Mac is named `jane-macbook` and your tailnet is `tail34ikjy`, your URL would be:
```
https://david-macbook.tail34ikjy.ts.net/send
```

## Usage

1. **Tap the Shortcut** on your iPhone
2. **Dictate your command** when prompted
3. **Wait for the response** - the shortcut will poll for updates
4. **View the output** in Quick Look
5. **Continue or stop** polling as needed

## Troubleshooting

### Connection Issues
- Ensure Tailscale is running on both devices
- Check that the bridge server is exposed via `tailscale serve`
- Verify the URL is correct in the shortcut

### Authentication Issues
- Ensure the token in the shortcut matches your Mac's token
- Check that the Authorization header format is correct: `Bearer TOKEN`

### No Response
- Check that Claude Code is running in the tmux session on your Mac
- Verify the bridge server is running: `curl http://127.0.0.1:8008/healthz`

### "Not Found" or "jobs" Errors
- Ensure you've added the "Get Dictionary Value" action to extract the `id` field
- The URL should be `/jobs/abc123/tail`, not `/jobs/Dictionary/tail`
- Check that "Dictionary Value" (not "Dictionary") is used in the Text action

### "Field required" or "missing body" Errors
- **Symptoms**: `{"detail":[{"loc":["body"],"type":"missing","msg":"Field required","input":null}]}`
- **Cause**: GET request to `/jobs/{id}/tail` is accidentally including a request body
- **Fix**: In Action 7 (Get Contents of URL for polling):
  - Ensure Method is set to `GET`
  - Ensure "Request Body" is set to `None` or completely empty
  - Do NOT include any JSON or request body for the polling requests
  - Only the initial `/send` request should have a request body
