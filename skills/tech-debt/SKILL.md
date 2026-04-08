---
name: tech-debt
description: Use when you want to surface accumulated technical debt — scans for TODOs, deprecated APIs, dead code, and code quality issues. Produces a prioritized list with age and estimated effort. Run periodically or before planning a refactor sprint.
allowed-tools: Agent
---

# Tech Debt Scan

Spawn the `scanner` agent in `tech-debt` mode:

```
Scan mode: tech-debt
Scope: $ARGUMENTS (scan entire repo if empty)

Run a full tech-debt scan:
- TODO / FIXME / HACK / XXX markers with git age
- Deprecated API usage for the detected stack
- Dead code candidates (unused exports, commented-out blocks)
- Code quality signals (files over 300 lines)

Return the structured findings report with 🔴 / 🟡 / 🟢 priority sections and summary stats.
```

Present the scanner's report to the user without modification.
