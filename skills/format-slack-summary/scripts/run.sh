#!/usr/bin/env bash
# Auto-generated script for format-slack-summary
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="format-slack-summary"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${SLACK_RECIPIENT_EMAIL:?ERROR: SLACK_RECIPIENT_EMAIL not set}"
: "${RUN_ID:?ERROR: RUN_ID not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/analyze-pr-risk_${RUN_ID}.json"
OUTPUT_FILE="/tmp/format-slack-summary_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os
from pathlib import Path

ctx=json.loads(Path(os.environ["INPUT_FILE"]).read_text())
out=Path(os.environ["OUTPUT_FILE"])
recipient=os.environ.get("SLACK_RECIPIENT_EMAIL", "shruti@ruh.ai")

def bullet(f):
    loc = f.get("file") or "unknown file"
    if f.get("line"): loc += f":{f['line']}"
    return f"• *{f.get('severity','low').title()}* ({f.get('confidence','unknown')} confidence) `{loc}` — {f.get('rationale')} Next: {f.get('recommended_next_step')}"

def section(title, items):
    if not items:
        return f"*{title}:* No notable issues found."
    return "\n".join([f"*{title}:*"] + [bullet(x) for x in items[:5]])

messages=[]
for r in ctx.get("reviews", []):
    md=r.get("metadata", {})
    title=md.get("title") or f"PR #{r.get('pr_number')}"
    url=md.get("pr_url") or ""
    author=md.get("author_login") or "unknown"
    status_note = ""
    if r.get("review_status") == "partial":
        status_note = f"\n_Partial review:_ {len(r.get('files_skipped') or [])} file(s) were skipped or truncated."
    elif r.get("review_status") == "failed":
        status_note = f"\n_Review failed:_ {r.get('error_message') or 'Unknown error'}."
    skipped = r.get("files_skipped") or []
    skipped_note = ""
    if skipped:
        compact = ", ".join([f"`{s.get('filename')}` ({s.get('reason')})" for s in skipped[:8]])
        more = "" if len(skipped) <= 8 else f" and {len(skipped)-8} more"
        skipped_note = f"\n*Skipped/limited files:* {compact}{more}"
    text = f"Hi Shruti — I reviewed PR #{r.get('pr_number')} in `{r.get('repository_full_name')}`: <{url}|{title}> by `{author}`. Overall risk: *{str(r.get('risk_level','unknown')).title()}*." \
      + status_note + "\n\n" \
      + section("Code quality / maintainability", r.get("code_quality_findings") or []) + "\n\n" \
      + section("Bug or logic risk", r.get("bug_risk_findings") or []) + "\n\n" \
      + section("Performance concerns", r.get("performance_findings") or []) \
      + skipped_note + "\n\nNo GitHub comments, approvals, checks, or merge-blocking actions were taken."
    messages.append({"review_id": r.get("review_id"), "recipient_email": recipient, "summary_text": text, "risk_level": r.get("risk_level"), "review_status": r.get("review_status"), "repository_full_name": r.get("repository_full_name"), "pr_number": r.get("pr_number"), "head_sha": r.get("head_sha")})
ctx["messages"] = messages
ctx["summary_text"] = "\n\n---\n\n".join(m["summary_text"] for m in messages) if messages else ""
out.write_text(json.dumps(ctx, indent=2))
PY

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: format-slack-summary complete"
