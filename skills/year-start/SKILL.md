---
name: year-start
description: Run the Year-Ahead Scan for the trading journal (CLAUDE.md Section 13, at /Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md). Global, MCP-only, context only. Invoke at the start of a new year.
allowed-tools: Read, Edit, Bash, Glob, mcp__trading-journal__*
---

# Year-Ahead Scan (global, MCP-only)

**Replaces the old project-local `/year-start`** (now archived at
`Journals/.claude/skills-legacy/year-start/`). Same reasoning as `week-start/SKILL.md`'s header.
`CLAUDE.md` at `/Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md` remains the rulebook.

**If anything this session suggests a rule should change**, per CLAUDE.md §20.14: add it to
CLAUDE.md §21.3, do not act on it.

**Context only, persists nothing to `journal_rollups`** — same as `month-start`/`quarter-start`:
the old system never wrote a file here either.

## Step 0 — confirm the MCP server is reachable

Call `get_account_state` first. If it fails, stop and explain `just run` needs to be running.

## Step 1 — resolve the year

Use the current year, unless the pilot gives one explicitly.

## Step 2 — run the scan

1. High-level scan of known major macro themes for the year — central bank policy paths,
   elections, known geopolitical calendar.
2. Fresh monthly-timeframe structural snapshot per instrument, informed by **`get_journal_rollups`**
   (`period: "quarterly"`, recent `limit`) for continuity rather than fresh chart analysis.

## Step 3 — write through MCP (calendar events only)

**`write_calendar_event`** — for each relevant event surfaced in Step 2.1. Leave `timeUtc` unset
and say so if unverified.
