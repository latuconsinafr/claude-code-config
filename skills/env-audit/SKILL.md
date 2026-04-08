---
name: env-audit
description: Use when you want to audit environment variable usage — scans the entire codebase for all env var references across all sources (code, Docker, CI, config files) and flags anything undocumented or inconsistent. Works for any stack and any env var pattern.
allowed-tools: Agent
---

# Environment Variable Audit

Spawn the `scanner` agent in `env-audit` mode:

```
Scan mode: env-audit
Scope: $ARGUMENTS (scan entire repo if empty)

Run a full env-audit scan:
- Collect all env var references in code (by detected stack/language)
- Collect all env var sources (.env files, Docker, CI configs, Terraform, serverless)
- Cross-reference and classify: missing, undocumented, stale, naming inconsistencies, clean

Return the structured findings report with 🔴 / 🟡 / 🟢 / ⚠️ sections and summary stats.
```

Present the scanner's report to the user without modification.
