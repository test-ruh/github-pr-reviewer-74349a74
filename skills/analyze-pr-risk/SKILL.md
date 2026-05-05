---
name: analyze-pr-risk
version: 1.0.0
description: "Produces structured maintainability, bug/logic, and performance findings from fetched PR diffs."
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [bash, python3]
      env: [RUN_ID]
    primaryEnv: None
---
# Analyze PR Risk

## I/O Contract

- **Input:** `/tmp/check-review-dedupe_${RUN_ID}.json`
- **Output:** `/tmp/analyze-pr-risk_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
