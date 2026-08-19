---
name: month-start
description: Run the Month-Ahead Scan for the trading journal (CLAUDE.md Section 13, at /Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md). Global, MCP-only, context only — creates no verdict, thesis, or hypothetical, and (matching the old system) persists nothing beyond any calendar events surfaced. Invoke on the first trading day of the month.
allowed-tools: Read, Edit, Bash, Glob, mcp__trading-journal__*
---

# Month-Ahead Scan (global, MCP-only)

**Replaces the old project-local `/month-start`** (now archived at
`Journals/.claude/skills-legacy/month-start/`). Same reasoning as `week-start/SKILL.md`'s header.
`CLAUDE.md` at `/Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md` remains the rulebook.

**If anything this session suggests a rule should change**, per CLAUDE.md §20.14: add it to
CLAUDE.md §21.3, do not act on it.

**This sets context only — same constraint as `week-start`.** No verdict, thesis, or hypothetical
here; those only originate from `/sod`. **Persists nothing to `journal_rollups` either** — checked
the old system first: `month-start` never wrote a file there (unlike `week-start`'s
`week_ahead_scan.md`), so there's no `monthAheadScanMd`-equivalent field to write to. This session
exists to inform the pilot, not to leave a record of itself.

## Step 0 — confirm the MCP server is reachable

Call `get_account_state` first. If it fails, stop and explain `just run` needs to be running.

## Step 1 — resolve the month

Use the current `YYYY-MM`, unless the pilot gives one explicitly.

## Step 2 — check what's changed since last month

- **`get_account_state`** — balance, `cumulativeDeposited`, `hardStopThreshold`, `sizingPhase`.
  This already reflects any deposit made since last month automatically (it's computed live from
  the deposit ledger, not something this skill recalculates) — just report what it says, including
  whether the sizing phase (§8) has crossed from A to B.
- **Whether XAU has become tradeable** — check the Accounts page in the webapp
  (`/accounts`, Instrument Specs section, `tradeableBalanceThreshold` for XAUUSD) against the
  current balance from the step above. No MCP tool reads instrument specs; this one's a quick
  visual check in the browser, not worth a dedicated tool for a single field.
- **MT5 server-time offset** — ask the pilot to re-verify against MT5 Market Watch; DST can flip
  it and there's no way for Claude to know the broker's current offset independently.
- **If a deposit needs recording**, point the pilot to the Accounts page's deposit ledger form
  (`/accounts`) — same "real entries go through the web form" pattern as trade entries, not
  something this skill writes on the pilot's behalf.

## Step 3 — run the scan

1. Scan the macro calendar for the month ahead — central bank meetings, major data releases —
   across all four instruments. Every time/date from the calendar itself (§19 primary sources).
2. Give a fresh weekly-timeframe structural snapshot per instrument. Inform this from
   **`get_journal_rollups`** (`period: "weekly"`, recent `limit`) — read the last few weeks'
   `overviewMd` for continuity — plus the pilot's own current view if they have one, rather than
   fresh chart analysis (that's `/sod`'s job, not this session's).

## Step 4 — write through MCP (calendar events only)

**`write_calendar_event`** — for each relevant event surfaced in Step 3.1. Leave `timeUtc` unset
and say so if it isn't verified against a primary source. Nothing else gets written this session
— see the header note on why `journal_rollups` isn't touched here.
