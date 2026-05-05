#!/usr/bin/env bash
# Auto-generated script for resolve-slack-recipient
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="resolve-slack-recipient"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${SLACK_BOT_TOKEN:?ERROR: SLACK_BOT_TOKEN not set}"
: "${SLACK_RECIPIENT_EMAIL:?ERROR: SLACK_RECIPIENT_EMAIL not set}"
: "${RUN_ID:?ERROR: RUN_ID not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/format-slack-summary_${RUN_ID}.json"
OUTPUT_FILE="/tmp/resolve-slack-recipient_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os, sys, time, urllib.parse, urllib.request, urllib.error
from pathlib import Path

ctx=json.loads(Path(os.environ["INPUT_FILE"]).read_text())
out=Path(os.environ["OUTPUT_FILE"])
token=os.environ["SLACK_BOT_TOKEN"]
email=os.environ.get("SLACK_RECIPIENT_EMAIL", "shruti@ruh.ai")

def slack(method, data=None, query=None):
    url="https://slack.com/api/"+method
    if query:
        url += "?" + urllib.parse.urlencode(query)
    body=None
    headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json; charset=utf-8"}
    if data is not None: body=json.dumps(data).encode()
    for attempt in range(3):
        req=urllib.request.Request(url, data=body, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                txt=resp.read().decode("utf-8","replace")
                js=json.loads(txt or "{}")
                if not js.get("ok"):
                    raise RuntimeError(f"Slack {method} returned ok=false: {txt[:1000]}
")
                return js
        except urllib.error.HTTPError as e:
            txt=e.read().decode("utf-8","replace")
            if e.code == 429 and attempt < 2:
                time.sleep(int(e.headers.get("Retry-After", "1") or "1")); continue
            print(f"Slack HTTP error {e.code} for {method}: {txt[:2000]}", file=sys.stderr); raise

try:
    user=slack("users.lookupByEmail", query={"email": email})["user"]["id"]
    chan=slack("conversations.open", data={"users": user})["channel"]["id"]
    ctx["slack_recipient"]={"recipient_email": email, "slack_user_id": user, "slack_channel_id": chan, "resolve_status": "resolved", "error_message": None}
except Exception as e:
    ctx["slack_recipient"]={"recipient_email": email, "slack_user_id": None, "slack_channel_id": None, "resolve_status": "failed", "error_message": str(e)}
out.write_text(json.dumps(ctx, indent=2))
PY

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: resolve-slack-recipient complete"
