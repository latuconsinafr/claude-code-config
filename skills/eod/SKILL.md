---
name: eod
description: Run the End-of-Day review for the trading journal (CLAUDE.md Section 12, at /Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md). Global, MCP-only — writes exclusively to the trading-journal MCP server, no markdown output. Auto-detects the gap since the last closed-out day, classifies each as PENDING or MISSED, then runs the full review. Invoke every evening.
allowed-tools: Read, Edit, Bash, Glob, mcp__trading-journal__*
---

# End of Day Review (global, MCP-only)

**Replaces the old project-local `/eod`** (formerly at `Journals/.claude/skills/eod/`, deferring
to `Journals/PROMPTS.md`). See `sod/SKILL.md`'s header for the same reasoning — that file is left
in place, unused. `CLAUDE.md` at `/Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md`
remains the rulebook; Section numbers below point there.

**If anything this session suggests a rule should change**, per CLAUDE.md §20.14: add it to
CLAUDE.md §21.3, do not act on it. Rule changes belong at quarter boundaries (§13).

**Instrument code mapping — required for every MCP call below, verified empirically 2026-08-18.**
Every MCP tool's `instrument` parameter is a full pair-code enum, not the EU/GU/UJ/XAU shorthand
used elsewhere in this file and in CLAUDE.md — confirmed by an actual rejected call during
`sod/SKILL.md`'s smoke test. Translate before every call: EU → `EURUSD`, GU → `GBPUSD`,
UJ → `USDJPY`, XAU → `XAUUSD`.

## Step 0 — confirm the MCP server is reachable

Same as `sod/SKILL.md` Step 0 — call `get_account_state` first. If it fails, stop, explain
`just run` needs to be running, and do not silently proceed as if anything here will be recorded.

## Step 1 — resolve the date, and scan the FULL gap via MCP state, not files

**Do not default to today's calendar date, and do not stop at the first pending day found.**

The old file-existence table (`verdict_summary.md` / `eod_review.md`) has a direct DB
equivalent — call **`get_session_completeness`** (recent, e.g. last 14 days) and classify each
date by its `sodDone`/`eodDone` flags:

| `session_completeness` state | Type | Treatment |
|---|---|---|
| `sodDone: true`, `eodDone: false` (or no row's `eodDone` set) | **PENDING** | Run the full EOD review — legitimate, retrospective |
| No row at all, or `sodDone: false` | **MISSED** | Mark missed. Never backfilled, never given a protocol run — see Step 5 |
| `sodDone: true`, `eodDone: true` | Closed | Not part of the gap |

**If the pilot gives an explicit date**, use it directly and skip the scan.

**Otherwise:**
1. Find the most recent date with both flags true — the last fully closed-out day.
2. List every calendar day strictly between that day and today, excluding Saturday and all of
   Sunday (market closed — see `evening/SKILL.md` Step 0).
3. Classify each per the table above.

Then:
- **Nothing in the gap** → say so, stop; fully caught up.
- **Exactly one PENDING, no MISSED** → run it directly.
- **Multiple PENDING** → list them, resolve oldest-first.
- **Any MISSED** → do not run a protocol for them. Handle per Step 5, then continue to whatever
  PENDING day remains.

## Step 2 — two different dates are in play

`[PENDING]` = the date the review is *about* (from Step 1). `[TODAY]` = the actual current date,
almost always when the charts were captured (per the pilot's routine, review happens the same
evening as tomorrow's SOD). Keep these separate throughout.

## Step 3 — work out which charts are required, before asking for anything

Call **`get_open_positions`** (any still `OPEN`), **`get_pending_hypotheticals`** (any pending
"wait for level" verdict), and **`get_calendar_events`** for `[PENDING]` (no `currency` filter —
check all four) to determine whether it carried a red-folder release. If nothing is on file for
that date, fall back to `get_daily_analysis`'s `checklistReasoning`/`verdictReason` text — SOD
sessions before 2026-08-18 predate this tool and may only have it recorded there. If neither
source makes it clear, ask the pilot directly rather than guessing.

State the requirement plainly before asking for anything:
- **D1 + H4 × all four instruments** — always required.
- **M15 for [instrument]** — only one with an open position, pending order, or active "wait for
  level" verdict.
- **M15 for all four** — only if `[PENDING]` carried a red-folder release.

**Never ask for more than this list.**

## Step 4 — locate the charts

Check, in order: **`charts/[TODAY]/`** (flat, normal case, shared with a same-session SOD half
via `/evening`) → **`charts/[TODAY]/eod/`** (standalone `/eod`, rare) → **`charts/[PENDING]/eod/`**
(only when `[PENDING]` and `[TODAY]` coincide). Ask only for what's missing, and say which
location was used.

## Step 5 — how to handle a MISSED day

**Do not run the review for a MISSED day. Never create a verdict or thesis for it, no matter how
much later this runs.** A thesis written with hindsight is worse than no thesis — it looks like a
real record.

What a MISSED day gets:
1. A short note in whichever PENDING/`[TODAY]` session is being reviewed this same sitting,
   naming the missed date(s) and stating nothing was reconstructed.
2. **`mark_session`** for that date: `sodDone: false, eodDone: false`, with a `missedNote`
   explaining what's known and what isn't.
3. **If a position was open going into the gap**, its outcome still gets resolved — real MT5
   history spanning the gap, via **`close_trade`** with the actual close time and exit price —
   but dated to when it was actually discovered/closed, never backdated. Resolving what a trade
   *did* is fact-finding; writing a thesis for a day already past is invention. Keep that
   distinction explicit when talking to the pilot.

Multiple consecutive MISSED days get one combined note, not one per day.

## Step 6 — run the review

In this order, all six sections:

1. **Positions.** Each open position: has the thesis changed? Distance to stop/target? Any
   management action, and did it follow the stated convention? Each closed position: win/loss,
   R-multiple, stated-convention adherence. For any trade opened on `[PENDING]`: was a Pre-Trade
   Check written *before* the click (§15 item 9) — score against that, say plainly if none
   exists.
2. **Pending/wait verdicts.** For each: was the condition met? Filled, still pending, invalidated
   (name the broken structural condition)?
3. **Verdict quality — all four instruments, including no-trade days.** Score decision quality
   (given only what was known at decision time, was the verdict correct per the rules?) and
   outcome (what actually happened) **separately, never collapsed**: good/good, good decision +
   bad outcome (a rule-following loss is a successful day), good + neutral, bad decision + good
   outcome (a lucky rule break is a failed day), bad/bad. Never say "should have seen X" if X
   wasn't visible at decision time.
4. **Learning note** (optional, 2–3 lines) — anything genuinely new observed, e.g. event-window
   normalisation time (feeds §6 calibration) or an unexpected level behavior. Observation only,
   never a rule change.
5. **Rule-consistent decisions with no checklist line** — e.g. declining a stop move, refusing an
   M15 setup against higher timeframes, holding "unclear" rather than forcing a read. Descriptive
   only, never scored (§15's binary integrity comes first).
6. **Circuit breakers** (§9) — flag any stand-down explicitly.

Constraints: do NOT resolve or score missed-opportunity hypotheticals here (weekly review does
that — note observationally whether price moved toward a hypothetical, don't mark it won/lost).
Do NOT propose rule changes here — CLAUDE.md §21.3 instead.

## Step 7 — write through MCP (the only write path)

**Find the real `tradeId` first — never guess it.** Call `get_open_positions` (or
`get_recent_trades` if already closed) and match by instrument, direction, and entry price.

1. **`close_trade`** — any trade that closed during the reviewed gap. Real MT5 close time and
   exit price, never discovery time (Step 5's fact-vs-invention distinction on MISSED-day gaps).
2. **`write_compliance_score`** — items 1–8, for any trade opened or managed on `[PENDING]`. Then
   resolve item 10 ("managed per that convention") for the same trade, using its real `tradeId`
   so this updates the existing row rather than duplicating. If items 9/10 were never written at
   open time, say so in `deviationNote` rather than marking them MET.
3. **`write_verdict_review`** — once per instrument, all four, for `[PENDING]` (including no-trade
   days) — Step 6.3's decision/outcome labels. Requires a `write_daily_analysis` row already on
   file for that instrument/date (SOD wrote it); if none exists, say so rather than guessing at
   what the verdict was.
4. **`mark_session`** — `eodDone: true` for `[PENDING]`, plus `learningNote` (Step 6.4, if
   anything was noted) and `ruleConsistentNotes` (Step 6.5, if any). For a MISSED day: `sodDone:
   false, eodDone: false` — **never `true`, regardless of how much later this runs.** The one call
   in this file that must never flip to done.
5. **`attach_chart`** — any EOD-specific M15 captures from Step 4, by path (same cross-machine
   caveat as `sod/SKILL.md` Step 3).

If any call fails partway through, stop and report exactly which succeeded and which didn't.
