# Step 5 of 5 — Access

## User Access

### Authorized Teams

| Team               | Access Level | Members (approx) |
|--------------------|-------------|-------------------|
| ruh-ai maintainers | manual invoke and view persisted summaries | Maintainers/operators responsible for `ruh-ai/ruh-dev-fe`. |
| Shruti | Slack DM recipient | shruti@ruh.ai only. |
| OpenClaw platform admins | configure env, provision persistence, and inspect runtime health | Authorized OpenClaw administrators. |

### Restricted From

| Team / Role          | Reason                          |
|----------------------|---------------------------------|
| PR authors and reviewers expecting GitHub-side enforcement | The agent is intentionally non-blocking and does not write to GitHub or affect mergeability. |
| Slack users other than Shruti | Summaries must be delivered only to the configured recipient. |
| Operators for unrelated repositories | Repository guardrail restricts scope to `ruh-ai/ruh-dev-fe` by default. |

## HiTL Approvers

| Skill                | Action                         | Approver             | Fallback Approver    |
|----------------------|--------------------------------|----------------------|----------------------|
| none | GitHub writes, merge blocking, or changing Slack recipients | Not allowed in this runtime | Refuse the action and persist/return a clear no-GitHub-action status. |

## Model Configuration

| Field                | Value                          |
|----------------------|--------------------------------|
| **Primary Model**    | claude-sonnet-4   |
| **Fallback Model**   | claude-haiku-3  |

## Token Budget

| Field                  | Value                  |
|------------------------|------------------------|
| **Monthly Budget**     | 1000000 tokens |
| **Alert Threshold**    | 800000 tokens |
| **Auto-Pause on Limit**| Yes |

## Security & Permissions

| Permission                         | Allowed    |
|------------------------------------|------------|
| Read GitHub PR metadata, files, commits, and diffs for TARGET_REPOSITORY | ✅ |
| Validate inbound GitHub webhook secret | ✅ |
| Write OpenClaw result tables prefixed with result_ | ✅ |
| Send Slack DM to SLACK_RECIPIENT_EMAIL only | ✅ |
| Post GitHub PR comments or inline reviews | ❌ |
| Create GitHub checks, statuses, labels, approvals, rejections, or merge actions | ❌ |
| Send Slack messages to channels or unconfigured recipients | ❌ |
| Execute destructive database operations | ❌ |
