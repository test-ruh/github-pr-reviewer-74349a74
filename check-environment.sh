#!/usr/bin/env bash
# Check required environment variables are set.
set -euo pipefail

missing=0
if [ -z "${PG_CONNECTION_STRING:-}" ]; then echo "MISSING: PG_CONNECTION_STRING"; missing=$((missing+1)); fi
if [ -z "${DATABASE_URL:-}" ]; then echo "MISSING: DATABASE_URL"; missing=$((missing+1)); fi
if [ -z "${ORG_ID:-}" ]; then echo "MISSING: ORG_ID"; missing=$((missing+1)); fi
if [ -z "${AGENT_ID:-}" ]; then echo "MISSING: AGENT_ID"; missing=$((missing+1)); fi
if [ -z "${GITHUB_TOKEN:-}" ]; then echo "MISSING: GITHUB_TOKEN"; missing=$((missing+1)); fi
if [ -z "${GITHUB_OWNER:-}" ]; then echo "MISSING: GITHUB_OWNER"; missing=$((missing+1)); fi
if [ -z "${AGENT_REPO_NAME:-}" ]; then echo "MISSING: AGENT_REPO_NAME"; missing=$((missing+1)); fi
if [ -z "${GITHUB_WEBHOOK_SECRET:-}" ]; then echo "MISSING: GITHUB_WEBHOOK_SECRET"; missing=$((missing+1)); fi
if [ -z "${TARGET_REPOSITORY:-}" ]; then echo "MISSING: TARGET_REPOSITORY"; missing=$((missing+1)); fi
if [ -z "${SLACK_BOT_TOKEN:-}" ]; then echo "MISSING: SLACK_BOT_TOKEN"; missing=$((missing+1)); fi
if [ -z "${SLACK_RECIPIENT_EMAIL:-}" ]; then echo "MISSING: SLACK_RECIPIENT_EMAIL"; missing=$((missing+1)); fi

if [ $missing -gt 0 ]; then
    echo "$missing required env var(s) missing"
    exit 1
fi
echo "OK: all required env vars set"
