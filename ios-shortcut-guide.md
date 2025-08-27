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
- Tap **+** to add action
- Search for "Dictate Text"
- Add the action
- Configure:
  - Language: Your preferred language
  - Stop Listening: After 30 seconds (or your preference)

#### Action 2: Dictionary
- Tap **+** to add action
- Search for "Dictionary"
- Add the action
- Configure:
  - Key: `text`
  - Value: `Dictated Text` (from previous action)
- Add another entry:
  - Key: `mode`
  - Value: `ask`

#### Action 3: Get Contents of URL (POST)
- Tap **+** to add action
- Search for "Get Contents of URL"
- Add the action
- Configure:
  - URL: `https://macbook-pro-4.tailb8bcda.ts.net/send`
  - Method: `POST`
  - Headers: Add new header
    - Key: `Authorization`
    - Value: `Bearer YOUR_TOKEN_HERE`
  - Headers: Add another header
    - Key: `Content-Type`
    - Value: `application/json`
  - Request Body: `Dictionary` (from previous action)

#### Action 4: Get Dictionary from Input
- Tap **+** to add action
- Search for "Get Dictionary from Input"
- Add the action
- Configure:
  - Input: `Contents of URL` (from previous action)

#### Action 4.5: Get Dictionary Value
- Tap **+** to add action
- Search for "Get Dictionary Value"
- Add the action
- Configure:
  - Input: `Dictionary` (from previous action)
  - Key: `id`

#### Action 4.6: Text (URL Construction)
- Tap **+** to add action
- Search for "Text"
- Add the action
- Configure:
  - Text: `https://macbook-pro-4.tailb8bcda.ts.net/jobs/Dictionary Value/tail?lines=100`
  - Note: "Dictionary Value" will be highlighted in orange, indicating it's a variable

#### Action 5: Repeat
- Tap **+** to add action
- Search for "Repeat"
- Add the action
- Configure:
  - Repeat: `6` times

#### Action 6: Wait (inside Repeat)
- Inside the Repeat action, tap **+**
- Search for "Wait"
- Add the action
- Configure:
  - Wait: `1` second

#### Action 7: Get Contents of URL (GET) (inside Repeat)
- Inside the Repeat action, tap **+**
- Search for "Get Contents of URL"
- Add the action
- Configure:
  - URL: `Text` (from Action 4.6 - this will be highlighted in orange)
  - Method: `GET`
  - Headers: Add header
    - Key: `Authorization`
    - Value: `Bearer YOUR_TOKEN_HERE`

#### Action 8: Quick Look (inside Repeat)
- Inside the Repeat action, tap **+**
- Search for "Quick Look"
- Add the action
- Configure:
  - Input: `Contents of URL` (from previous action)

#### Action 9: Ask for Input (inside Repeat)
- Inside the Repeat action, tap **+**
- Search for "Ask for Input"
- Add the action
- Configure:
  - Prompt: `Stop polling? (y/N)`
  - Default Answer: `N`

#### Action 10: If (inside Repeat)
- Inside the Repeat action, tap **+**
- Search for "If"
- Add the action
- Configure:
  - Input: `Provided Input`
  - Condition: `is`
  - Value: `y`

#### Action 11: Exit Shortcut (inside If)
- Inside the If action, tap **+**
- Search for "Exit Shortcut"
- Add the action

## Configuration Notes

### Replace Placeholders
- `YOUR-MAC`: Your Mac's hostname
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
If your Mac is named `nathan-macbook` and your tailnet is `nathan.ts.net`, your URL would be:
```
https://nathan-macbook.nathan.ts.net/send
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

## Advanced Configuration

### Customize Polling
- Change the repeat count for more/fewer updates
- Adjust the wait time between polls
- Add error handling for failed requests

### Add Notifications
- Add "Show Notification" action to alert when responses arrive
- Include response previews in notifications

### Save Responses
- Add "Save File" action to store responses locally
- Use "Append to File" to create conversation logs
