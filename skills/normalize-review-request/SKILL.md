---
name: normalize-review-request
version: 1.0.0
description: "Normalizes webhook, manual, or fallback inputs into an in-scope GitHub PR review request."
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [python3]
      env: [TARGET_REPOSITORY, SLACK_RECIPIENT_EMAIL, GITHUB_WEBHOOK_SECRET, RUN_ID]
    primaryEnv: TARGET_REPOSITORY
---
# Normalize Review Request

## I/O Contract

- **Input:** `/tmp/trigger_${RUN_ID}.json`
- **Output:** `/tmp/normalize-review-request_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
