---
name: persist-review-records
version: 1.0.0
description: "Persists PR metadata, review summaries, Slack delivery records, and processed-event markers."
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [python3]
      env: [DATABASE_URL, ORG_ID, AGENT_ID, RUN_ID, SLACK_RECIPIENT_EMAIL]
    primaryEnv: DATABASE_URL
---
# Persist Review Records

## I/O Contract

- **Input:** `/tmp/format-slack-summary_${RUN_ID}.json`
- **Output:** `/tmp/persist-review-records_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
