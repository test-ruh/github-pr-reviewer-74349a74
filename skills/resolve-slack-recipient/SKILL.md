---
name: resolve-slack-recipient
version: 1.0.0
description: Resolves the configured recipient email to Slack IDs for deployments that cannot address native message() by email.
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [bash, python3, curl, jq]
      env: [SLACK_BOT_TOKEN, SLACK_RECIPIENT_EMAIL, RUN_ID]
    primaryEnv: SLACK_BOT_TOKEN
---
# Resolve Slack Recipient

## I/O Contract

- **Input:** `/tmp/format-slack-summary_${RUN_ID}.json`
- **Output:** `/tmp/resolve-slack-recipient_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
