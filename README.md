# 🔍 GitHub PR Reviewer

Reviews new and manually requested PRs in ruh-ai/ruh-dev-fe and DMs concise risk summaries to Shruti without taking any GitHub action.

## Quick Start

```bash
git clone git@github.com:${GITHUB_OWNER}/github-pr-reviewer.git
cd github-pr-reviewer

# 1. Configure
cp .env.example .env
# Edit .env with your credentials (see "Required Environment Variables" below)

# 2. One-shot setup: validates env, installs deps, provisions DB, registers cron
chmod +x setup.sh
./setup.sh
```

## Manual Setup (if you prefer step-by-step)

```bash
cp .env.example .env             # then edit it
set -a; source .env; set +a       # load vars into the current shell
bash check-environment.sh         # verify everything required is set
bash install-dependencies.sh      # pip install psycopg2-binary, pyyaml
python3 scripts/data_writer.py provision   # create tables in your schema
openclaw cron add --file cron/fallback-open-pr-poll.json
```

## Running

```bash
bash test-workflow.sh             # run every skill in order locally (smoke test)
openclaw cron run --name fallback-open-pr-poll    # trigger manually
openclaw cron list                # see registered jobs
openclaw cron runs                # see run history
```

## Required Environment Variables

| Variable | Description |
|----------|-------------|
| `PG_CONNECTION_STRING` | PostgreSQL connection string used by OpenClaw persistence |
| `DATABASE_URL` | PostgreSQL connection string used by data_writer.py and read-only dedupe checks |
| `ORG_ID` | OpenClaw organization id for schema isolation |
| `AGENT_ID` | OpenClaw agent id for schema isolation |
| `GITHUB_TOKEN` | Read-only GitHub token for ruh-ai/ruh-dev-fe PR metadata, files, commits, and diffs |
| `GITHUB_OWNER` | GitHub owner for artifact sync repository |
| `AGENT_REPO_NAME` | GitHub repository name for artifact sync |
| `GITHUB_WEBHOOK_SECRET` | Secret used to validate incoming GitHub pull_request webhook signatures |
| `TARGET_REPOSITORY` | Only repository this agent may review; default ruh-ai/ruh-dev-fe |
| `SLACK_BOT_TOKEN` | Slack bot token for native OpenClaw Slack DM delivery |
| `SLACK_RECIPIENT_EMAIL` | Slack DM recipient email; expected shruti@ruh.ai |

## Skills

| Skill | Mode | Description |
|-------|------|-------------|
| `data-writer` | Auto | Provision, write, and query the agent database schema via scripts/data_writer.py. Use for all PostgreSQL operations and any result-table persistence. |
| `result-query` | User-invocable | Read stored records from the agent result tables for inspection and follow-up questions. |
| `github-action` | User-invocable | Git branch + PR workflow for syncing agent changes to GitHub. Creates feature branches, commits changes, and opens pull requests against main. NEVER pushes to main directly. MANDATORY for every agent. |
| `normalize-review-request` | Auto | Normalizes webhook, manual, or fallback inputs into an in-scope GitHub PR review request. |
| `fetch-github-pr-context` | Auto | Fetches PR metadata, commits, changed files, and bounded diffs from GitHub. |
| `check-review-dedupe` | Auto | Decides whether each fetched PR should be reviewed and notified based on prior automatic reviews. |
| `analyze-pr-risk` | Auto | Produces structured maintainability, bug/logic, and performance findings from fetched PR diffs. |
| `format-slack-summary` | Auto | Converts structured PR review findings into concise Slack-ready DM text. |
| `resolve-slack-recipient` | Auto | Resolves the configured recipient email to Slack IDs for deployments that cannot address native message() by email. |
| `persist-review-records` | Auto | Persists PR metadata, review summaries, Slack delivery records, and processed-event markers. |

## Scheduled Jobs

| Job Name | Schedule | Notes |
|----------|----------|-------|
| `fallback-open-pr-poll` | `*/30 * * * *` | Timezone: UTC |


## Architecture

- **Runtime**: OpenClaw AI agent framework
- **Data Layer**: PostgreSQL via `scripts/data_writer.py`
- **Scheduling**: OpenClaw cron
- **Schema**: `org_{org_id}_a_github_pr_reviewer`

## Directory Structure

```
github-pr-reviewer/
├── README.md
├── openclaw.json
├── result-schema.yml
├── env-manifest.yml
├── .env.example
├── requirements.txt
├── .gitignore
├── check-environment.sh
├── install-dependencies.sh
├── test-workflow.sh
├── cron/
├── workflows/
├── scripts/
│   ├── data_writer.py
│   └── github_action.py
├── skills/
└── workspace/
    ├── SOUL.md
    ├── 01_IDENTITY.md
    ├── 02_RULES.md
    ├── 03_SKILLS.md
    ├── 04_TRIGGERS.md
    ├── 05_ACCESS.md
    ├── 06_WORKFLOW.md
    └── 07_REVIEW.md
```
