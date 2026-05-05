#!/usr/bin/env bash
# Auto-generated script for fetch-github-pr-context
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="fetch-github-pr-context"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${GITHUB_TOKEN:?ERROR: GITHUB_TOKEN not set}"
: "${TARGET_REPOSITORY:?ERROR: TARGET_REPOSITORY not set}"
: "${RUN_ID:?ERROR: RUN_ID not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/normalize-review-request_${RUN_ID}.json"
OUTPUT_FILE="/tmp/fetch-github-pr-context_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os, sys, time, urllib.request, urllib.error
from pathlib import Path

api = "https://api.github.com"
token = os.environ["GITHUB_TOKEN"]
target = os.environ.get("TARGET_REPOSITORY", "ruh-ai/ruh-dev-fe")
max_diff_bytes = int(os.environ.get("MAX_DIFF_BYTES", "200000"))
max_files = int(os.environ.get("MAX_FILES_PER_PR", "80"))
req = json.loads(Path(os.environ["INPUT_FILE"]).read_text())
out = Path(os.environ["OUTPUT_FILE"])

def gh(path, accept="application/vnd.github+json"):
    url = api + path
    headers = {"Authorization": f"Bearer {token}", "Accept": accept, "X-GitHub-Api-Version": "2022-11-28", "User-Agent": "openclaw-github-pr-reviewer"}
    for attempt in range(4):
        r = urllib.request.Request(url, headers=headers)
        try:
            with urllib.request.urlopen(r, timeout=30) as resp:
                body = resp.read().decode("utf-8", "replace")
                if accept.endswith("diff"):
                    return body, resp.status
                return json.loads(body or "null"), resp.status
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", "replace")
            if e.code in (429, 500, 502, 503, 504) and attempt < 3:
                retry = int(e.headers.get("Retry-After", "0") or "0")
                time.sleep(retry or (2 ** attempt))
                continue
            print(f"GitHub API error {e.code} for {url}: {body[:2000]}", file=sys.stderr)
            raise

if req.get("repository_full_name") != target or not req.get("valid", False):
    out.write_text(json.dumps({**req, "prs": [], "fetch_status": "skipped", "error_message": req.get("refusal_reason")}, indent=2))
    sys.exit(0)
owner_repo = req["repository_full_name"]
if req.get("all_open"):
    prs_json, _ = gh(f"/repos/{owner_repo}/pulls?state=open&per_page=100")
    pr_numbers = [p["number"] for p in prs_json]
else:
    pr_numbers = req.get("pr_numbers", [])

prs = []
for n in pr_numbers:
    try:
        pr, _ = gh(f"/repos/{owner_repo}/pulls/{n}")
        commits, _ = gh(f"/repos/{owner_repo}/pulls/{n}/commits?per_page=100")
        files, _ = gh(f"/repos/{owner_repo}/pulls/{n}/files?per_page=100")
        diff_text, _ = gh(f"/repos/{owner_repo}/pulls/{n}", "application/vnd.github.v3.diff")
        reviewed=[]; skipped=[]; total=0
        selected_files = files[:max_files]
        if len(files) > max_files:
            for f in files[max_files:]: skipped.append({"filename": f.get("filename"), "reason": "max_files_per_pr_exceeded"})
        for f in selected_files:
            fn=f.get("filename",""); patch=f.get("patch") or ""; status=f.get("status")
            if not patch:
                skipped.append({"filename": fn, "reason": "binary_or_patch_unavailable", "status": status}); continue
            if total + len(patch.encode()) > max_diff_bytes:
                skipped.append({"filename": fn, "reason": "max_diff_bytes_exceeded", "status": status}); continue
            total += len(patch.encode()); reviewed.append(fn)
        metadata = {
          "repository_full_name": owner_repo, "pr_number": pr["number"], "pr_url": pr.get("html_url"),
          "title": pr.get("title"), "author_login": (pr.get("user") or {}).get("login"),
          "base_branch": (pr.get("base") or {}).get("ref"), "head_branch": (pr.get("head") or {}).get("ref"),
          "head_sha": (pr.get("head") or {}).get("sha"), "state": pr.get("state"),
          "opened_at": pr.get("created_at"), "updated_at_github": pr.get("updated_at"),
          "changed_files_count": pr.get("changed_files"), "additions": pr.get("additions"), "deletions": pr.get("deletions"),
          "raw_metadata": {"mergeable": pr.get("mergeable"), "draft": pr.get("draft"), "labels": [l.get("name") for l in pr.get("labels", [])]}
        }
        prs.append({"metadata": metadata, "commits": [{"sha": c.get("sha"), "message": (c.get("commit") or {}).get("message"), "author": (((c.get("commit") or {}).get("author") or {}).get("name"))} for c in commits], "files": files, "diffs": {"unified_diff_truncated": diff_text[:max_diff_bytes]}, "files_reviewed": reviewed, "files_skipped": skipped, "truncated": len(diff_text.encode()) > max_diff_bytes or bool(skipped), "fetch_status": "partial" if skipped else "completed", "error_message": None})
    except Exception as e:
        prs.append({"metadata": {"repository_full_name": owner_repo, "pr_number": n}, "commits": [], "files": [], "diffs": {}, "files_reviewed": [], "files_skipped": [], "truncated": False, "fetch_status": "failed", "error_message": str(e)})

out.write_text(json.dumps({**req, "prs": prs, "fetch_status": "completed" if prs else "empty"}, indent=2))
PY

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: fetch-github-pr-context complete"
