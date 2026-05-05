---
name: fetch-github-pr-context
version: 1.0.0
description: "Fetches PR metadata, commits, changed files, and bounded diffs from GitHub."
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [bash, python3, curl, jq]
      env: [GITHUB_TOKEN, TARGET_REPOSITORY, RUN_ID]
    primaryEnv: GITHUB_TOKEN
---
# Fetch GitHub PR Context

## I/O Contract

- **Input:** `/tmp/normalize-review-request_${RUN_ID}.json`
- **Output:** `/tmp/fetch-github-pr-context_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
