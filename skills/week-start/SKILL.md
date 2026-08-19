---
name: week-start
description: Run the Week-Ahead Scan for the trading journal (CLAUDE.md Section 13, at /Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md). Global, MCP-only — writes exclusively through the trading-journal MCP server, no markdown output. Context only — creates no verdict, thesis, or hypothetical. Invoke Sunday evening or Monday morning, before that day's daily session.
allowed-tools: Read, Bash, Glob, mcp__trading-journal__*
---

# Week-Ahead Scan (global, MCP-only)

**Replaces the old project-local `/week-start`** (formerly at `Journals/.claude/skills/week-start/`,
deferring to `Journals/PROMPTS.md`). Same reasoning as `sod/SKILL.md`'s header — that file and
`PROMPTS.md` are left in place, unused. `CLAUDE.md` at
`/Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md` remains the rulebook; §13 governs this
cadence's cascade rule.

**Instrument code mapping — same as `sod/SKILL.md`.** MCP calls need the full pair code, not the
EU/GU/UJ/XAU shorthand: EU → `EURUSD`, GU → `GBPUSD`, UJ → `USDJPY`, XAU → `XAUUSD`.

**This sets context only.** It must not produce a verdict, a thesis, or a logged hypothetical —
those only ever originate from a daily (`/sod`) session. If asked to give a directional call here,
decline and point to `/sod` instead.

## Step 0 — confirm the MCP server is reachable

Same as every other skill in this set — call `get_account_state` first. If it fails, stop, explain
`just run` needs to be running in `webapp/`, and do not proceed as if anything here will be
recorded.

## Step 1 — resolve the week

**Compute the ISO week with `date +%G-W%V`** (confirmed empirically 2026-08-19 to zero-pad
correctly, e.g. `2026-W34`, `2026-W02` for single-digit weeks) — unless the pilot gives one
explicitly. **Never hand-construct this string** — `get_journal_rollups` sorts `periodKey` as
plain text, and an unpadded week number (`2026-W5`) sorts in the wrong place relative to
`2026-W31`. This is not cosmetic; getting it wrong silently corrupts every cascade read that
follows.

## Step 2 — check whether this week's scan already exists

Call **`get_journal_rollups`** (`period: "weekly"`, small `limit`, e.g. 4). If a row for this
exact week's `periodKey` already has `weekAheadScanMd` set, confirm with the pilot before
overwriting rather than silently replacing it.

## Step 3 — gather what the scan needs

- From the same `get_journal_rollups` call: the **immediately prior** week's `overviewMd` (the
  highest `periodKey` strictly less than this week's), for the "has anything shifted since last
  week" comparison. If none exists yet (this is early in the practice), say so plainly — there's
  nothing to compare against yet, not an error.
- **`get_calendar_events`** for the days in the week ahead, per currency (USD/EUR/GBP/JPY) — or
  ask the pilot for anything not yet on file if this is being run before that research has
  happened.
- If the pilot has longer-range D1 charts to share for a fresher structural read, ask; otherwise
  work from `get_daily_analysis`'s recent history per instrument plus public calendar sources.

## Step 4 — run the scan, in this order

1. Scan the economic calendar for the full week ahead across all four instruments — flag every
   high-impact event with its scheduled time (WIB, plus server and ET). Every time and date comes
   from the calendar itself (§19 primary sources) — leave a forecast/previous value blank and say
   so if it can't be verified, never guess.
2. Give a fresh D1 structural snapshot per instrument — has anything shifted since last week's
   overview (Step 3)? Name the **next** level above and below current price, not just the nearest
   one, so the week's R:R arithmetic has something to work with once a daily session finds a
   setup.
3. Note any event-risk windows (§6) to be aware of early in the week, and which sessions are
   actually unobstructed by them.
4. Flag which days carry a red-folder release, so `/sod`/`/eod` know to capture M15 on those
   days regardless of position status (§6's measurement-method requirement).

## Step 5 — write through MCP (the only write path)

1. **`write_calendar_event`** — for each relevant event surfaced in Step 4.1. Leave `timeUtc`
   unset and say so if it isn't verified against a primary source.
2. **`write_journal_rollup`** — `period: "weekly"`, this week's `periodKey`, **`weekAheadScanMd`
   only** (the Step 4 scan content). Do not set `overviewMd`/`reflectionMd`/compliance fields here
   — those belong to `week-end`, and setting them now with placeholder content would corrupt what
   `week-end` writes later (the upsert merges by field, so leaving them unset here is what keeps
   `week-end`'s later write clean, not a limitation to work around).

If either call fails, stop and report exactly what succeeded and what didn't, rather than
silently treating the scan as fully recorded.
