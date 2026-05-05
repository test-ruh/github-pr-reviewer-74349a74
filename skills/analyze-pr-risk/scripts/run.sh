#!/usr/bin/env bash
# Auto-generated script for analyze-pr-risk
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="analyze-pr-risk"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${RUN_ID:?ERROR: RUN_ID not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/check-review-dedupe_${RUN_ID}.json"
OUTPUT_FILE="/tmp/analyze-pr-risk_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os, re, uuid
from pathlib import Path

ctx = json.loads(Path(os.environ["INPUT_FILE"]).read_text())
out = Path(os.environ["OUTPUT_FILE"])

def finding(category, severity, file, line, confidence, rationale, next_step):
    return {"category": category, "severity": severity, "file": file, "line": line, "confidence": confidence, "rationale": rationale, "recommended_next_step": next_step}

def classify_file_patch(f):
    fn=f.get("filename",""); patch=f.get("patch") or ""
    cq=[]; bug=[]; perf=[]
    line=None
    for m in re.finditer(r"@@ .*? \+(\d+)", patch):
        line=int(m.group(1)); break
    if len(patch.splitlines()) > 300:
        cq.append(finding("code_quality", "medium", fn, line, "medium", "Large single-file change can be harder to review and maintain.", "Consider splitting responsibilities or adding focused tests around changed behavior."))
    if re.search(r"console\.log\(|debugger;", patch):
        cq.append(finding("code_quality", "low", fn, line, "high", "Debug logging or debugger statement appears in added code.", "Remove debug statements before merge unless intentionally gated."))
    if re.search(r"TODO|FIXME", patch, re.I):
        cq.append(finding("code_quality", "low", fn, line, "medium", "New TODO/FIXME marker may indicate incomplete follow-up work.", "Confirm whether this is acceptable for this PR or track it explicitly."))
    if re.search(r"useEffect\s*\([^\n]*=>", patch) and re.search(r"\+\s*}\s*,\s*\[\s*\]\s*\)", patch):
        bug.append(finding("bug_logic", "medium", fn, line, "medium", "A React effect with an empty dependency array may capture stale props/state.", "Verify dependencies or document why one-time execution is correct."))
    if re.search(r"==[^=]|!=[^=]", patch):
        bug.append(finding("bug_logic", "low", fn, line, "medium", "Loose equality appears in changed code.", "Prefer strict equality unless coercion is intentional and tested."))
    if re.search(r"catch\s*\([^)]*\)\s*{\s*}", patch, re.S):
        bug.append(finding("bug_logic", "medium", fn, line, "medium", "Empty catch block can hide runtime failures.", "Handle, log, or intentionally document the swallowed error."))
    if re.search(r"\.map\([^)]*\).*\.filter\(|\.filter\([^)]*\).*\.map\(", patch, re.S):
        perf.append(finding("performance", "low", fn, line, "low", "Chained array transforms may add avoidable work on large collections.", "Consider combining passes if this runs on large lists or hot render paths."))
    if re.search(r"localStorage|sessionStorage", patch) and re.search(r"render|return\s*\(", patch):
        perf.append(finding("performance", "low", fn, line, "low", "Synchronous browser storage access may be in or near render flow.", "Move storage reads outside hot render paths where practical."))
    return cq, bug, perf

def risk(cq, bug, perf, skipped, failed=False):
    if failed: return "unknown"
    severities=[x["severity"] for x in cq+bug+perf]
    if "high" in severities: return "high"
    if severities.count("medium") >= 2 or "medium" in severities: return "medium"
    if severities or skipped: return "low"
    return "low"

reviews=[]
for item in ctx.get("reviewable_prs", []):
    md=item.get("metadata", {})
    cq=[]; bug=[]; perf=[]
    if item.get("fetch_status") == "failed":
        status="failed"; err=item.get("error_message") or "GitHub fetch failed"
    else:
        status="partial" if item.get("files_skipped") or item.get("truncated") else "completed"; err=None
        for f in item.get("files", []):
            if f.get("filename") in item.get("files_reviewed", []):
                a,b,c = classify_file_patch(f); cq += a; bug += b; perf += c
    reviews.append({"review_id": str(uuid.uuid4()), "repository_full_name": md.get("repository_full_name"), "pr_number": md.get("pr_number"), "head_sha": md.get("head_sha"), "trigger_type": ctx.get("trigger_type"), "requested_by": ctx.get("requested_by"), "metadata": md, "risk_level": risk(cq, bug, perf, item.get("files_skipped"), status=="failed"), "review_status": status, "code_quality_findings": cq, "bug_risk_findings": bug, "performance_findings": perf, "files_reviewed": item.get("files_reviewed", []), "files_skipped": item.get("files_skipped", []), "analysis_summary": "Heuristic diff review completed; findings are risk signals, not merge decisions.", "error_message": err})
ctx["reviews"] = reviews
out.write_text(json.dumps(ctx, indent=2))
PY

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: analyze-pr-risk complete"
