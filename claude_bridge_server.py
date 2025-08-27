#!/usr/bin/env python3
import os, time, json, subprocess, hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse, PlainTextResponse
from pydantic import BaseModel

# ---- Config ----
ENV = {}
with open(os.path.expanduser("~/.claude-bridge/.env")) as f:
    for line in f:
        line=line.strip()
        if not line or line.startswith("#"): continue
        k,v = line.split("=",1); ENV[k]=os.path.expandvars(v)

PORT = int(ENV.get("PORT","8008"))
TMUX_TARGET = ENV.get("TMUX_TARGET","claude:0.0")
MAX_CAPTURE_LINES = int(ENV.get("MAX_CAPTURE_LINES","2000"))
CAPTURE_DELAY_MS = int(ENV.get("CAPTURE_DELAY_MS","1500"))
BEARER_TOKEN = Path(ENV["BEARER_TOKEN_FILE"]).read_text().strip()
LOG_FILE = ENV.get("LOG_FILE", os.path.expanduser("~/.claude-bridge/logs/bridge.log"))
STATE_DIR = Path(os.path.expanduser("~/.claude-bridge/state"))
STATE_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="Claude Bridge", version="1.0")

class SendReq(BaseModel):
    text: str
    id: Optional[str] = None
    mode: Optional[str] = "ask"
    workdir: Optional[str] = None
    wait_ms: Optional[int] = None

def _now_iso():
    return datetime.now(timezone.utc).isoformat(timespec='seconds')

def _log(**kv):
    with open(LOG_FILE,"a") as f:
        kv["ts"]= _now_iso()
        f.write(json.dumps(kv, ensure_ascii=False)+"\n")

def _tmux_send(line: str):
    subprocess.run(["tmux","send-keys","-t",TMUX_TARGET,line,"C-m"], check=True)

def _tmux_capture(lines: int):
    out = subprocess.run(["tmux","capture-pane","-t",TMUX_TARGET,"-p","-S",f"-{lines}"],
                         check=True, capture_output=True, text=True).stdout
    return out

def _require_auth(req: Request):
    hdr = req.headers.get("authorization","")
    return hdr.startswith("Bearer ") and hdr.split(" ",1)[1].strip() == BEARER_TOKEN

@app.middleware("http")
async def auth_mw(request: Request, call_next):
    if request.url.path not in ("/healthz",):
        if not _require_auth(request):
            return JSONResponse({"error":"unauthorized"}, status_code=401)
    return await call_next(request)

@app.get("/healthz")
def healthz():
    try:
        subprocess.run(["tmux","list-panes","-t",TMUX_TARGET], check=True, capture_output=True)
        ok=True
    except Exception:
        ok=False
    return {"ok": ok, "tmux_target": TMUX_TARGET}

@app.post("/send")
def send(req: SendReq):
    req_id = req.id or hashlib.sha1((req.text+_now_iso()).encode()).hexdigest()[:12]
    marker = f"<<<BRIDGE_START id={req_id}>>>"
    _log(event="accept", id=req_id, mode=req.mode, workdir=req.workdir, n_chars=len(req.text))
    if req.workdir:
        _tmux_send(f"(workdir hint) {req.workdir}")
    _tmux_send(marker)
    for line in req.text.splitlines():
        _tmux_send(line)
    time.sleep((req.wait_ms or CAPTURE_DELAY_MS)/1000.0)
    pane = _tmux_capture(MAX_CAPTURE_LINES)
    idx = pane.rfind(marker)
    snippet = pane[idx+len(marker):].strip() if idx!=-1 else pane.strip()
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=PORT)
