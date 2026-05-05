# Review — Final Summary Before Deployment

## Agent Card

| Field              | Value                          |
|--------------------|--------------------------------|
| **Name**           | 🔍 GitHub PR Reviewer |
| **ID**             | `github-pr-reviewer`           |
| **Version**        | 1.0.0 |
| **Scope**          | Reviews new and manually requested PRs in ruh-ai/ruh-dev-fe and DMs concise risk summaries to Shruti without taking any GitHub action.      |
| **Tone**           | Professional, concise, engineering-focused, confidence-aware, and non-alarmist.             |
| **Model**          | claude-sonnet-4 (primary), claude-haiku-3 (fallback) |
| **Token Budget**   | 1000000 tokens/month |

## Skills Summary

| Skill                     | Mode         |
|---------------------------|--------------|
| Data Writer | 🟢 Auto |
| Result Query | 🟢 Auto |
| GitHub Action | 🟢 Auto |
| Normalize Review Request | 🟢 Auto |
| Fetch GitHub PR Context | 🟢 Auto |
| Check Review Dedupe | 🟢 Auto |
| Analyze PR Risk | 🟢 Auto |
| Format Slack Summary | 🟢 Auto |
| Resolve Slack Recipient | 🟢 Auto |
| Persist Review Records | 🟢 Auto |

## Post-Deployment Checklist

- [ ] Set DATABASE_URL or PG_CONNECTION_STRING, ORG_ID, AGENT_ID, GITHUB_TOKEN, GITHUB_WEBHOOK_SECRET, TARGET_REPOSITORY=ruh-ai/ruh-dev-fe, SLACK_BOT_TOKEN, and SLACK_RECIPIENT_EMAIL=shruti@ruh.ai.
- [ ] Provision result tables from result-schema.yml using data_writer.py.
- [ ] Run check-environment.sh and test-workflow.sh with valid environment values.
- [ ] Verify GitHub token has read-only behavior and no GitHub write endpoints are configured.
- [ ] Verify Slack app can DM `shruti@ruh.ai`.
- [ ] Keep ENABLE_FALLBACK_POLL=false until webhook delivery is confirmed unavailable.
- [ ] Perform a manual review against an open PR and confirm Slack summary plus result records.
- [ ] Confirm duplicate automatic event for same PR/head SHA records skipped_duplicate and sends no second Slack DM.
