#!/usr/bin/env bash
# Auto-generated script for persist-review-records
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="persist-review-records"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${DATABASE_URL:?ERROR: DATABASE_URL not set}"
: "${ORG_ID:?ERROR: ORG_ID not set}"
: "${AGENT_ID:?ERROR: AGENT_ID not set}"
: "${RUN_ID:?ERROR: RUN_ID not set}"
: "${SLACK_RECIPIENT_EMAIL:?ERROR: SLACK_RECIPIENT_EMAIL not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/format-slack-summary_${RUN_ID}.json"
OUTPUT_FILE="/tmp/persist-review-records_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os, uuid, datetime
from pathlib import Path

ctx=json.loads(Path(os.environ["INPUT_FILE"]).read_text())
out=Path(os.environ["OUTPUT_FILE"])
run_id=os.environ["RUN_ID"]
recipient=os.environ.get("SLACK_RECIPIENT_EMAIL", ctx.get("recipient_email", "shruti@ruh.ai"))
now=datetime.datetime.utcnow().replace(microsecond=0).isoformat()+"Z"
metadata_records=[]
for p in ctx.get("prs", []):
    md=p.get("metadata") or {}
    if md.get("repository_full_name") and md.get("pr_number") and md.get("head_sha"):
        metadata_records.append({**md, "run_id": run_id})
review_records=[]
for r in ctx.get("reviews", []):
    msg = next((m for m in ctx.get("messages", []) if m.get("review_id") == r.get("review_id")), {})
    review_records.append({"review_id": r.get("review_id"), "repository_full_name": r.get("repository_full_name"), "pr_number": r.get("pr_number"), "head_sha": r.get("head_sha"), "trigger_type": r.get("trigger_type") or ctx.get("trigger_type"), "requested_by": r.get("requested_by") or ctx.get("requested_by"), "risk_level": r.get("risk_level", "unknown"), "summary_text": msg.get("summary_text") or r.get("analysis_summary") or "Review summary unavailable.", "code_quality_findings": r.get("code_quality_findings", []), "bug_risk_findings": r.get("bug_risk_findings", []), "performance_findings": r.get("performance_findings", []), "files_reviewed": r.get("files_reviewed", []), "files_skipped": r.get("files_skipped", []), "review_status": r.get("review_status", "failed"), "error_message": r.get("error_message"), "run_id": run_id})
for p in ctx.get("skipped_prs", []):
    d=p.get("dedupe") or {}; md=p.get("metadata") or {}
    if d.get("is_duplicate"):
        review_records.append({"review_id": str(uuid.uuid4()), "repository_full_name": md.get("repository_full_name"), "pr_number": md.get("pr_number"), "head_sha": md.get("head_sha"), "trigger_type": ctx.get("trigger_type"), "requested_by": ctx.get("requested_by"), "risk_level": "unknown", "summary_text": "Automatic duplicate review skipped; no Slack notification sent.", "code_quality_findings": [], "bug_risk_findings": [], "performance_findings": [], "files_reviewed": [], "files_skipped": [], "review_status": "skipped_duplicate", "error_message": d.get("reason"), "run_id": run_id})
notification_records=[]
delivery = ctx.get("delivery_results") or ctx.get("message_result") or {}
for m in ctx.get("messages", []):
    status = "sent" if delivery.get("ok") or delivery.get("message_ts") or delivery.get("ts") else "pending"
    if delivery.get("error"): status="failed"
    notification_records.append({"review_id": m.get("review_id"), "recipient_email": recipient, "slack_user_id": delivery.get("slack_user_id") or delivery.get("user_id"), "slack_channel_id": delivery.get("slack_channel_id") or delivery.get("channel"), "message_ts": delivery.get("message_ts") or delivery.get("ts"), "delivery_status": status, "error_message": delivery.get("error"), "sent_at": now if status == "sent" else None, "run_id": run_id})
for p in ctx.get("skipped_prs", []):
    if (p.get("dedupe") or {}).get("is_duplicate"):
        rid = next((r["review_id"] for r in review_records if r.get("pr_number") == (p.get("metadata") or {}).get("pr_number") and r.get("review_status") == "skipped_duplicate"), str(uuid.uuid4()))
        notification_records.append({"review_id": rid, "recipient_email": recipient, "delivery_status": "skipped_duplicate", "error_message": "automatic_duplicate_same_pr_head_sha", "run_id": run_id})
event_records=[]
base_key=ctx.get("event_key") or f"{ctx.get('source','manual')}:{run_id}"
for p in ctx.get("prs", []) or [{}]:
    md=p.get("metadata") or {}
    suffix = md.get("head_sha") or md.get("pr_number") or "request"
    d=p.get("dedupe") or {}
    event_records.append({"source": ctx.get("source", ctx.get("trigger_type", "manual")), "event_key": base_key if len(ctx.get("prs", [])) <= 1 else f"{base_key}:{suffix}", "repository_full_name": md.get("repository_full_name") or ctx.get("repository_full_name"), "pr_number": md.get("pr_number"), "head_sha": md.get("head_sha"), "action": ctx.get("action"), "processed_status": "skipped_duplicate" if d.get("is_duplicate") else ("failed" if p.get("fetch_status") == "failed" else "processed"), "payload_excerpt": ctx.get("payload_excerpt", {}), "run_id": run_id})
result={"metadata_records": metadata_records, "review_records": review_records, "notification_records": notification_records, "event_records": event_records, "counts": {"metadata": len(metadata_records), "reviews": len(review_records), "notifications": len(notification_records), "events": len(event_records)}}
out.write_text(json.dumps(result, indent=2))
PY

if [ "$(python3 -c 'import json,os; print(len(json.load(open(os.environ["OUTPUT_FILE"])).get("metadata_records",[])))')" != "0" ]; then
  python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_pr_metadata --conflict "repository_full_name,pr_number,head_sha" --run-id "${RUN_ID}" --records "$(python3 -c 'import json,os; print(json.dumps(json.load(open(os.environ["OUTPUT_FILE"]))["metadata_records"]))')"
fi
if [ "$(python3 -c 'import json,os; print(len(json.load(open(os.environ["OUTPUT_FILE"])).get("review_records",[])))')" != "0" ]; then
  python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_pr_review_summary --conflict "review_id" --run-id "${RUN_ID}" --records "$(python3 -c 'import json,os; print(json.dumps(json.load(open(os.environ["OUTPUT_FILE"]))["review_records"]))')"
fi
if [ "$(python3 -c 'import json,os; print(len(json.load(open(os.environ["OUTPUT_FILE"])).get("notification_records",[])))')" != "0" ]; then
  python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_slack_notification --conflict "review_id,recipient_email" --run-id "${RUN_ID}" --records "$(python3 -c 'import json,os; print(json.dumps(json.load(open(os.environ["OUTPUT_FILE"]))["notification_records"]))')"
fi
if [ "$(python3 -c 'import json,os; print(len(json.load(open(os.environ["OUTPUT_FILE"])).get("event_records",[])))')" != "0" ]; then
  python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_processed_event --conflict "source,event_key" --run-id "${RUN_ID}" --records "$(python3 -c 'import json,os; print(json.dumps(json.load(open(os.environ["OUTPUT_FILE"]))["event_records"]))')"
fi

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: persist-review-records complete"
