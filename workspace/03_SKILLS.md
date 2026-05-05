# Step 3 of 5 — Skills

## Added Skills

| #    | Skill ID                  | Skill Name               | Mode   | Risk Level | Description                |
|------|---------------------------|--------------------------|--------|------------|----------------------------|
| S1   | `data-writer` | Data Writer | Auto | Low | Provision, write, and query the agent database schema via scripts/data_writer.py. Use for all PostgreSQL operations and any result-table persistence. |
| S2   | `result-query` | Result Query | Auto | Low | Read stored records from the agent result tables for inspection and follow-up questions. |
| S3   | `github-action` | GitHub Action | Auto | Low | Git branch + PR workflow for syncing agent changes to GitHub. Creates feature branches, commits changes, and opens pull requests against main. NEVER pushes to main directly. MANDATORY for every agent. |
| S4   | `normalize-review-request` | Normalize Review Request | Auto | Low | Normalizes webhook, manual, or fallback inputs into an in-scope GitHub PR review request. |
| S5   | `fetch-github-pr-context` | Fetch GitHub PR Context | Auto | Low | Fetches PR metadata, commits, changed files, and bounded diffs from GitHub. |
| S6   | `check-review-dedupe` | Check Review Dedupe | Auto | Low | Decides whether each fetched PR should be reviewed and notified based on prior automatic reviews. |
| S7   | `analyze-pr-risk` | Analyze PR Risk | Auto | Low | Produces structured maintainability, bug/logic, and performance findings from fetched PR diffs. |
| S8   | `format-slack-summary` | Format Slack Summary | Auto | Low | Converts structured PR review findings into concise Slack-ready DM text. |
| S9   | `resolve-slack-recipient` | Resolve Slack Recipient | Auto | Low | Resolves the configured recipient email to Slack IDs for deployments that cannot address native message() by email. |
| S10   | `persist-review-records` | Persist Review Records | Auto | Low | Persists PR metadata, review summaries, Slack delivery records, and processed-event markers. |

## Skill Dependencies (Execution Order)

```
data-writer
result-query
github-action
normalize-review-request
fetch-github-pr-context ← depends on normalize-review-request
check-review-dedupe ← depends on fetch-github-pr-context
analyze-pr-risk ← depends on check-review-dedupe
format-slack-summary ← depends on analyze-pr-risk
resolve-slack-recipient ← depends on format-slack-summary
persist-review-records ← depends on fetch-github-pr-context, check-review-dedupe, analyze-pr-risk, format-slack-summary
```

## Execution Mode Summary

| Mode  | Count          |
|-------|----------------|
| HiTL  | 0              |
| Auto  | 10 |
