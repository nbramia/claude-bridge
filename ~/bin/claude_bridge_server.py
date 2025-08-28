#!/usr/bin/env python3
import os, time, json, subprocess, hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse, PlainTextResponse, HTMLResponse
from pydantic import BaseModel

# ---- Config ----
PORT = 8008
TMUX_SESSION = "claude"
STATE_DIR = Path.home() / ".claude-bridge" / "jobs"
LOG_DIR = Path.home() / ".claude-bridge" / "logs"

# Ensure directories exist
STATE_DIR.mkdir(parents=True, exist_ok=True)
LOG_DIR.mkdir(parents=True, exist_ok=True)

# ---- Models ----
class SendReq(BaseModel):
    text: str
    mode: Optional[str] = "ask"
    workdir: Optional[str] = None
    id: Optional[str] = None
    wait_ms: Optional[int] = 2000

# ---- FastAPI App ----
app = FastAPI(title="Claude Bridge Server")

# ---- Helper Functions ----
def _now_iso():
    return datetime.now(timezone.utc).isoformat()

def _log(event: str, **kwargs):
    log_entry = {
        "timestamp": _now_iso(),
        "event": event,
        **kwargs
    }
    log_file = LOG_DIR / "bridge.log"
    with open(log_file, "a") as f:
        f.write(json.dumps(log_entry) + "\n")

def _tmux_send(keys):
    """Send keys to tmux session"""
    try:
        subprocess.run([
            "tmux", "send-keys", "-t", TMUX_SESSION, keys
        ], check=True, capture_output=True)
    except subprocess.CalledProcessError as e:
        _log(event="tmux_send_error", error=str(e), keys=keys)
        raise HTTPException(status_code=500, detail=f"tmux error: {e}")

def _tmux_capture(max_lines: int = 1000) -> str:
    """Capture tmux pane content"""
    try:
        result = subprocess.run([
            "tmux", "capture-pane", "-t", TMUX_SESSION, "-p", "-S", f"-{max_lines}"
        ], check=True, capture_output=True, text=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        _log(event="tmux_capture_error", error=str(e))
        raise HTTPException(status_code=500, detail=f"tmux capture error: {e}")

# ---- Endpoints ----
@app.get("/healthz")
def healthz():
    """Health check endpoint"""
    try:
        # Check if tmux session exists
        result = subprocess.run([
            "tmux", "list-sessions", "-F", "#{session_name}"
        ], capture_output=True, text=True)
        
        if TMUX_SESSION in result.stdout:
            return {"ok": True, "tmux_target": f"{TMUX_SESSION}:0.0"}
        else:
            return {"ok": False, "error": "tmux session not found"}
    except Exception as e:
        return {"ok": False, "error": str(e)}

@app.post("/send")
def send(req: SendReq):
    req_id = req.id or hashlib.sha1((req.text+_now_iso()).encode()).hexdigest()[:12]
    _log(event="accept", id=req_id, mode=req.mode, workdir=req.workdir, n_chars=len(req.text))

    # Simple approach: just send the user's text to Claude
    # Assumes Claude is already running in the right directory
    # You manually start Claude Code in ~/Documents/Code before using the bridge

    # Send the user's text as a message to Claude Code
    command_text = req.text.strip()
    if command_text:
        _tmux_send(command_text)
        _tmux_send("C-m")  # Send Enter key to submit the message to Claude

    time.sleep((req.wait_ms or 2000)/1000.0)
    pane = _tmux_capture(1000)
    snippet = pane.strip()  # Just capture the pane content
    (STATE_DIR / f"{req_id}.txt").write_text(snippet)
    _log(event="delivered", id=req_id, n_lines=len(snippet.splitlines()))
    return {"id": req_id, "status": "accepted", "preview": snippet[-2000:]}

@app.get("/jobs/{req_id}/tail")
def tail(req_id: str, lines: int = 400):
    p = STATE_DIR / f"{req_id}.txt"
    if not p.exists():
        return JSONResponse({"error":"unknown id"}, status_code=404)
    text = p.read_text()
    return PlainTextResponse("\n".join(text.splitlines()[-lines:]))

@app.get("/jobs/{req_id}/live")
def live_view(req_id: str):
    """Live updating HTML view of the job"""
    p = STATE_DIR / f"{req_id}.txt"
    if not p.exists():
        return JSONResponse({"error":"unknown id"}, status_code=404)
    
    text = p.read_text()
    lines = text.splitlines()
    
    # Create HTML with auto-refresh
    html = f"""
<!DOCTYPE html>
<html>
<head>
    <title>Claude Bridge - Live View</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {{
            font-family: 'SF Mono', Monaco, 'Cascadia Code', monospace;
            background: #1a1a1a;
            color: #e0e0e0;
            margin: 0;
            padding: 20px;
            line-height: 1.4;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
        }}
        .header {{
            background: #2a2a2a;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            border-left: 4px solid #4CAF50;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
        }}
        .header-left {{
            display: flex;
            flex-direction: column;
            gap: 5px;
        }}
        .content {{
            background: #0d1117;
            padding: 20px;
            border-radius: 8px;
            border: 1px solid #30363d;
            white-space: pre-wrap;
            font-size: 14px;
            max-height: 80vh;
            overflow-y: auto;
        }}
        .status {{
            color: #4CAF50;
            font-weight: bold;
        }}
        .timestamp {{
            color: #888;
            font-size: 12px;
        }}
        .auto-refresh {{
            color: #FFA500;
            font-size: 12px;
        }}
        .refresh-btn {{
            background: #4CAF50;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            margin-left: 10px;
        }}
        .refresh-btn:hover {{
            background: #45a049;
        }}
    </style>
    <script>
        // Auto-scroll to bottom on load
        window.addEventListener('load', function() {{
            const content = document.querySelector('.content');
            content.scrollTop = content.scrollHeight;
        }});
        
        // Manual refresh function
        function refreshPage() {{
            window.location.reload();
        }}
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="header-left">
                <div class="status">🟢 Claude Bridge - Live View</div>
                <div class="timestamp">Last updated: {datetime.now().strftime('%H:%M:%S')}</div>
            </div>
            <button class="refresh-btn" onclick="refreshPage()">🔄 Refresh</button>
        </div>
        <div class="content">{text}</div>
    </div>
</body>
</html>
"""
    
    return HTMLResponse(html)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=PORT)



