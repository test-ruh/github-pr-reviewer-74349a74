---
name: format-slack-summary
version: 1.0.0
description: "Converts structured PR review findings into concise Slack-ready DM text."
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [python3]
      env: [SLACK_RECIPIENT_EMAIL, RUN_ID]
    primaryEnv: SLACK_RECIPIENT_EMAIL
---
# Format Slack Summary

## I/O Contract

- **Input:** `/tmp/analyze-pr-risk_${RUN_ID}.json`
- **Output:** `/tmp/format-slack-summary_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
