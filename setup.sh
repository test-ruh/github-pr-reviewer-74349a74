#!/usr/bin/env bash
# One-time setup for GitHub PR Reviewer.
# Idempotent — safe to run multiple times.
set -euo pipefail

cd "$(dirname "$0")"

echo "Setting up GitHub PR Reviewer (github-pr-reviewer)"
echo ""

echo "[1/5] Preparing .env..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "  created .env from .env.example — EDIT IT before continuing"
    echo "  required vars listed in README.md → 'Required Environment Variables'"
    exit 1
fi
echo "  .env exists"

echo ""
echo "[2/5] Validating environment..."
# shellcheck disable=SC1091
set -a; source .env; set +a
bash check-environment.sh

echo ""
echo "[3/5] Installing Python dependencies..."
bash install-dependencies.sh

echo ""
echo "[4/5] Provisioning database schema..."
python3 scripts/data_writer.py provision

echo ""
echo "[5/5] Registering cron jobs..."
if command -v openclaw >/dev/null 2>&1; then
if openclaw cron list 2>/dev/null | grep -q "^fallback-open-pr-poll\b"; then
    echo "  cron job 'fallback-open-pr-poll' already registered — skipping"
else
    openclaw cron add --file cron/fallback-open-pr-poll.json && echo "  registered cron job 'fallback-open-pr-poll'"
fi
else
    echo "  WARNING: 'openclaw' CLI not found in PATH — register cron jobs manually:"
    echo "    openclaw cron add --file cron/fallback-open-pr-poll.json"
fi

echo ""
echo "OK: GitHub PR Reviewer is ready."
echo ""
echo "Useful commands:"
echo "  bash test-workflow.sh                      # smoke-test all skills locally"
echo "  openclaw cron run --name fallback-open-pr-poll    # trigger manually"
echo "  python3 scripts/data_writer.py query --table <name> --limit 10"
