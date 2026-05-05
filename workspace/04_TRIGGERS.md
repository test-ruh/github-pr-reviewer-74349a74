# Step 4 of 5 — Triggers

## Active Triggers

### github-pr-opened-webhook — GitHub `pull_request` webhook with `action=opened` for `ruh-ai/ruh-dev-fe`; payload includes repository, PR number, URL, and head SHA.

| Field       | Value                              |
|-------------|------------------------------------|
| **Type**    | event                     |
| **Status**  | required                   |
| **Channel** | github_webhook |

**Sample User Queries This Trigger Handles:**

- "GitHub pull_request.opened event for ruh-ai/ruh-dev-fe PR #123"

---

### manual-pr-review-request — Operator requests review of a PR number, PR URL, or all open PRs; optional `force=true` permits re-review.

| Field       | Value                              |
|-------------|------------------------------------|
| **Type**    | conversational                     |
| **Status**  | required                   |
| **Channel** | openclaw_manual |

**Sample User Queries This Trigger Handles:**

- "Review PR #123"
- "Review https://github.com/ruh-ai/ruh-dev-fe/pull/123"
- "Review all open PRs in ruh-ai/ruh-dev-fe with force=true"

---

### fallback-open-pr-poll — Scheduled fallback checks open PRs when GitHub webhook delivery is unavailable; controlled by ENABLE_FALLBACK_POLL.

| Field       | Value                              |
|-------------|------------------------------------|
| **Type**    | scheduled                     |
| **Status**  | optional                   |
| **Channel** | cron |
| **Frequency**   | Every 30 minutes UTC                       |
| **Cron**        | `*/30 * * * *`                        |

