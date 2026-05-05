---
name: check-review-dedupe
version: 1.0.0
description: Decides whether each fetched PR should be reviewed and notified based on prior automatic reviews.
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [python3]
      env: [DATABASE_URL, ORG_ID, AGENT_ID, RUN_ID]
    primaryEnv: DATABASE_URL
---
# Check Review Dedupe

## I/O Contract

- **Input:** `/tmp/fetch-github-pr-context_${RUN_ID}.json`
- **Output:** `/tmp/check-review-dedupe_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
