#!/usr/bin/env bash
# Auto-generated script for check-review-dedupe
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="check-review-dedupe"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${DATABASE_URL:?ERROR: DATABASE_URL not set}"
: "${ORG_ID:?ERROR: ORG_ID not set}"
: "${AGENT_ID:?ERROR: AGENT_ID not set}"
: "${RUN_ID:?ERROR: RUN_ID not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/fetch-github-pr-context_${RUN_ID}.json"
OUTPUT_FILE="/tmp/check-review-dedupe_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os, sys
from pathlib import Path

ctx = json.loads(Path(os.environ["INPUT_FILE"]).read_text())
out = Path(os.environ["OUTPUT_FILE"])
trigger_type = ctx.get("trigger_type")
force = bool(ctx.get("force"))
try:
    import psycopg
except Exception:
    psycopg = None

def schema_name():
    return f"org_{os.environ['ORG_ID']}_a_{os.environ['AGENT_ID']}".replace('-', '_')

def prior_auto_review(repo, pr, sha):
    if trigger_type == "manual" or force or not psycopg or not sha:
        return False
    q = f"select 1 from {schema_name()}.result_pr_review_summary where repository_full_name=%s and pr_number=%s and head_sha=%s and trigger_type in ('event','fallback_poll') and review_status in ('completed','partial') limit 1"
    try:
        with psycopg.connect(os.environ["DATABASE_URL"]) as conn, conn.cursor() as cur:
            cur.execute(q, (repo, pr, sha)); return cur.fetchone() is not None
    except Exception as e:
        print(f"Dedupe DB read failed; proceeding to review to avoid missing coverage: {e}", file=sys.stderr)
        return False

reviewable=[]; skipped=[]
for item in ctx.get("prs", []):
    md = item.get("metadata", {})
    repo, pr, sha = md.get("repository_full_name"), md.get("pr_number"), md.get("head_sha")
    if item.get("fetch_status") == "failed":
        dedupe = {"should_review": False, "should_notify": True, "is_duplicate": False, "reason": "fetch_failed"}
    elif prior_auto_review(repo, pr, sha):
        dedupe = {"should_review": False, "should_notify": False, "is_duplicate": True, "reason": "automatic_duplicate_same_pr_head_sha"}
    else:
        dedupe = {"should_review": True, "should_notify": True, "is_duplicate": False, "reason": "manual_or_new_head_sha" if (trigger_type == "manual" or force) else "new_automatic_review"}
    item["dedupe"] = dedupe
    (reviewable if dedupe["should_review"] else skipped).append(item)
ctx["reviewable_prs"] = reviewable
ctx["skipped_prs"] = skipped
ctx["should_review"] = bool(reviewable)
ctx["should_notify"] = any((p.get("dedupe") or {}).get("should_notify") for p in ctx.get("prs", []))
out.write_text(json.dumps(ctx, indent=2))
PY

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: check-review-dedupe complete"
