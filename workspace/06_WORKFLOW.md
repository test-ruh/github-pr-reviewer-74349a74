# Workflow — End-to-End Process Flow

## Workflow Steps

1. **data-writer** → data-writer
2. **normalize** → normalize-review-request
3. **fetch_context** → fetch-github-pr-context (depends on normalize)
4. **check_dedupe** → check-review-dedupe (depends on fetch_context)
5. **analyze** → analyze-pr-risk (depends on check_dedupe)
6. **format_summary** → format-slack-summary (depends on analyze)
7. **resolve_recipient** → resolve-slack-recipient (depends on format_summary)
8. **send_slack_dm** → native-tool: message (depends on format_summary, resolve_recipient)
9. **persist_records** → persist-review-records (depends on send_slack_dm, fetch_context, check_dedupe, analyze, format_summary)

## Diagram

```
data-writer → normalize → fetch_context → check_dedupe → analyze → format_summary → resolve_recipient → send_slack_dm → persist_records
```
