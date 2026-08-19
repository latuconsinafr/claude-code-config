---
name: month-end
description: Run the Monthly Review for the trading journal (CLAUDE.md Section 13, at /Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md). Global, MCP-only — writes exclusively through the trading-journal MCP server, no markdown output. Aggregates the month's weekly rollups into compliance and R-multiple trends. Invoke at month close, after that month's weekly reviews are done.
allowed-tools: Read, Edit, Bash, Glob, mcp__trading-journal__*
---

# Monthly Review (global, MCP-only)

**Replaces the old project-local `/month-end`** (now archived at
`Journals/.claude/skills-legacy/month-end/`). `CLAUDE.md` at
`/Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md` remains the rulebook — this is the
first skill in the set to actually exercise §13's cascade rule for real: **this reads the level
below (weekly rollups), not raw daily data.** If a specific number looks wrong, the §13 drill-down
fallback still applies — open the underlying week's data via `get_daily_analysis`/
`get_compliance_scores` rather than guessing, but that's the exception, not the default path.

**If anything this session suggests a rule should change**, per CLAUDE.md §20.14: add it to
CLAUDE.md §21.3, do not act on it.

## Step 0 — confirm the MCP server is reachable

Call `get_account_state` first. If it fails, stop and explain `just run` needs to be running.

## Step 1 — resolve the month and find its weeks

Use the current `YYYY-MM`, unless the pilot gives one explicitly.

Call **`get_journal_rollups`** (`period: "weekly"`, `limit: 6` covers any calendar month with
room to spare). From the returned rows, pick out the ones that belong to this month — **the
convention: a week belongs to the month its Monday falls in.** State this explicitly if a week
spans the boundary (e.g. starts in the prior month) rather than silently applying it; there's no
single universally-correct definition for a week that spans two months, so being explicit about
which convention was used matters more than the convention itself.

**If a week that should exist has no row** (a Monday inside this month with no matching
`periodKey`), that week's `week-end` was never run. **Do not backfill it — note the gap
explicitly** in the monthly overview, same "never silently shrink the sample" principle as
`week-end` Step 2. State how many of the month's weeks actually have a complete rollup.

## Step 2 — run the review

1. **Aggregate compliance % and R-multiple trend for the month** — from the weekly rollups found
   in Step 1, not raw daily/compliance data (that's exactly what the cascade rule exists to
   avoid re-reading every time). Verdict, execution, and session completeness reported
   **separately, never merged**:
   - `complianceOverall`/`complianceVerdict`/`complianceExecution`: **average** across the
     included weeks (each is already a rate/percentage, not additive).
   - `totalR`: **sum** across the included weeks (R is additive across time).
   - Session completeness: report as "N of M weeks had a complete rollup" (Step 1's gap check),
     not a percentage of daily sessions — that granularity already lives in each week's own
     figure.
2. **Produce the weekly-timeframe monthly overview** — synthesize from the included weeks'
   `overviewMd` content, not fresh chart analysis.
3. **Note (do not adopt)** any pattern worth flagging for the quarterly review, and confirm
   CLAUDE.md §21.3 is current (read it; this step doesn't require anything be added, just that
   it's been looked at).

## Step 3 — write through MCP (the only write path)

**`write_journal_rollup`** — `period: "monthly"`, this month's `periodKey` (`"2026-08"`).
`overviewMd` (Step 2.2), `reflectionMd` (any monthly-level reflection beyond the weekly-level
detail — optional, don't force content that's just a restatement of the weeks), the three
compliance fields and `totalR` from Step 2.1.

If the call fails, stop and report it rather than treating the review as recorded.
