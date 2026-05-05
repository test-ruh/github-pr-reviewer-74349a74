#!/usr/bin/env bash
# Auto-generated script for normalize-review-request
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="normalize-review-request"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${TARGET_REPOSITORY:?ERROR: TARGET_REPOSITORY not set}"
: "${SLACK_RECIPIENT_EMAIL:?ERROR: SLACK_RECIPIENT_EMAIL not set}"
: "${GITHUB_WEBHOOK_SECRET:?ERROR: GITHUB_WEBHOOK_SECRET not set}"
: "${RUN_ID:?ERROR: RUN_ID not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/trigger_${RUN_ID}.json"
OUTPUT_FILE="/tmp/normalize-review-request_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os, re, sys, hashlib
from pathlib import Path

inp = Path(os.environ["INPUT_FILE"])
out = Path(os.environ["OUTPUT_FILE"])
target = os.environ.get("TARGET_REPOSITORY", "ruh-ai/ruh-dev-fe")
recipient = os.environ.get("SLACK_RECIPIENT_EMAIL", "shruti@ruh.ai")
raw = json.loads(inp.read_text() or "{}") if inp.exists() else {}
trigger_payload = raw.get("trigger_payload") if isinstance(raw.get("trigger_payload"), dict) else raw
manual_args = raw.get("manual_args") if isinstance(raw.get("manual_args"), dict) else {}
source_hint = raw.get("source") or trigger_payload.get("source") or manual_args.get("source")

repo = None; pr_number = None; action = None; head_sha = None; pr_url = None
requested_by = raw.get("requested_by") or manual_args.get("requested_by") or trigger_payload.get("sender", {}).get("login")
force = bool(raw.get("force") or manual_args.get("force") or trigger_payload.get("force"))
all_open = bool(raw.get("all_open") or manual_args.get("all_open") or trigger_payload.get("all_open"))

if "pull_request" in trigger_payload:
    pr = trigger_payload.get("pull_request") or {}
    repo = (trigger_payload.get("repository") or {}).get("full_name")
    pr_number = pr.get("number") or trigger_payload.get("number")
    action = trigger_payload.get("action")
    head_sha = (pr.get("head") or {}).get("sha")
    pr_url = pr.get("html_url")
    trigger_type = "event"
    source = "github"
elif source_hint == "fallback_poll" or all_open and source_hint in ("fallback_poll", "cron"):
    repo = raw.get("repository_full_name") or manual_args.get("repository_full_name") or trigger_payload.get("repository_full_name") or target
    trigger_type = "fallback_poll"
    source = "fallback_poll"
    action = "poll_open"
else:
    args = {**trigger_payload, **manual_args, **raw}
    repo = args.get("repository_full_name") or args.get("repository") or target
    if isinstance(repo, dict): repo = repo.get("full_name")
    pr_number = args.get("pr_number") or args.get("number")
    pr_url = args.get("pr_url") or args.get("url")
    if not pr_number and pr_url:
        m = re.search(r"github\.com/([^/]+/[^/]+)/pull/(\d+)", pr_url)
        if m:
            repo, pr_number = m.group(1), int(m.group(2))
    trigger_type = "manual"
    source = "manual"
    action = "requested"

if pr_number is not None:
    try: pr_number = int(pr_number)
    except Exception: pr_number = None

valid = True; refusal_reason = None
if repo != target:
    valid = False; refusal_reason = f"out_of_scope_repository:{repo}"
if trigger_type == "event" and action != "opened":
    valid = False; refusal_reason = f"ignored_github_action:{action}"
if not all_open and not pr_number:
    valid = False; refusal_reason = refusal_reason or "missing_pr_number_or_all_open"

if all_open:
    event_key = f"{source}:{target}:all-open:{os.environ.get('RUN_ID','unknown')}"
else:
    suffix = head_sha or "requested"
    event_key = f"{source}:{target}:pr:{pr_number}:{suffix}"

payload_excerpt = {"repository_full_name": repo, "pr_number": pr_number, "action": action, "head_sha": head_sha, "all_open": all_open}
result = {
  "repository_full_name": repo or target, "target_repository": target, "trigger_type": trigger_type,
  "source": source, "action": action, "event_key": event_key, "force": force,
  "all_open": all_open, "pr_numbers": ([] if all_open or pr_number is None else [pr_number]),
  "requested_by": requested_by, "recipient_email": recipient, "valid": valid,
  "refusal_reason": refusal_reason, "payload_excerpt": payload_excerpt
}
out.write_text(json.dumps(result, indent=2))
PY

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: normalize-review-request complete"
