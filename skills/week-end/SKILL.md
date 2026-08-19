---
name: week-end
description: Run the Weekly Review for the trading journal (CLAUDE.md Section 13, at /Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md). Global, MCP-only — writes exclusively through the trading-journal MCP server, no markdown output. Aggregates the week's daily sessions, resolves missed-opportunity hypotheticals, tallies the rejection-reason counter. Invoke Friday close or Sunday, after the week's daily sessions are done.
allowed-tools: Read, Edit, Bash, Glob, mcp__trading-journal__*
---

# Weekly Review (global, MCP-only)

**Replaces the old project-local `/week-end`** (formerly at `Journals/.claude/skills/week-end/`,
now archived at `Journals/.claude/skills-legacy/`, deferring to `Journals/PROMPTS.md`). Same
reasoning as `sod/SKILL.md`'s header. `CLAUDE.md` at
`/Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md` remains the rulebook.

**If anything this session suggests a rule should change**, per CLAUDE.md §20.14: add it to
CLAUDE.md §21.3, do not act on it. Rule changes belong at quarter boundaries (§13).

**Instrument code mapping — same as `sod/SKILL.md`.** EU → `EURUSD`, GU → `GBPUSD`,
UJ → `USDJPY`, XAU → `XAUUSD`.

## Step 0 — confirm the MCP server is reachable

Call `get_account_state` first. If it fails, stop — `just run` needs to be running in `webapp/`
— and do not proceed as if anything here will be recorded.

## Step 1 — resolve the week

**`date +%G-W%V`** (zero-padded, see `week-start/SKILL.md` for why this matters — an unpadded
week number sorts wrong in every cascade read that follows), unless the pilot gives one
explicitly.

## Step 2 — confirm the week's daily sessions are actually complete

Call **`get_session_completeness`** (enough days back to cover the full week, e.g. `limit: 10`).
For every calendar day in the week (Mon–Fri; weekends are never trading days, per
`evening/SKILL.md` Step 0): does that date show `sodDone: true` AND `eodDone: true`?

- **Both true** → that day is complete, part of the sample.
- **Either false, or no row at all** → that day was a skipped session. **Note it as missed in the
  overview. Do not backfill it, and do not let the gap silently shrink the week's sample** — say
  explicitly how many of the 5 possible days actually have a complete record.

## Step 3 — gather what the week needs

- **`get_daily_analysis`** — once per instrument, `sinceDate` = the Monday of this week. Filter
  the returned rows client-side to this week's dates only (the tool returns everything since that
  date, not bounded to one week) — this gives verdicts, `decisionQuality`/`outcomeQuality`
  (written by each day's `/eod`), and `checklistReasoning` text for the rejection-reason tally in
  Step 5.
- **`get_pending_hypotheticals`** (no instrument filter — all four) — then filter client-side to
  this week's `date` range. A hypothetical from an earlier week still showing PENDING here means
  an earlier weekly review missed it; note that explicitly rather than silently resolving it as
  if it were this week's.
- **`get_compliance_scores`** — `dateFrom`/`dateTo` spanning the week — for the compliance %
  calculation in Step 4.
- **`get_recent_trades`** — `closedFrom`/`closedTo` spanning the week (use end-of-day boundaries,
  e.g. `closedTo: "[FRIDAY]T23:59:59"` — see that tool's own description for why a bare date isn't
  enough) — for total R and win/loss count.
- **`get_calendar_events`** for each day in the week (no currency filter) — needed to check
  whether a triggered hypothetical fell inside a §6 event window (Step 4.4).

## Step 4 — run the review, in this order

1. **Aggregate the week's verdicts and outcomes** from Step 3's `get_daily_analysis` results —
   what was decided each day, and (from `decisionQuality`/`outcomeQuality`) how it actually
   played out.
2. **D1-level weekly overview per instrument** — has the higher-timeframe swing structure changed
   this week? Synthesize from the daily structural reads gathered in Step 3, not fresh chart
   analysis (that's `/sod`'s job).
3. **Weekly process compliance % and total R (§15), plus session completeness — three separate
   figures, never merged.** Compliance: bucket Step 3's `get_compliance_scores` rows into
   decision-quality (items 1–6) vs. execution-quality (items 7–10), matching
   `write_journal_rollup`'s own split; `EXCLUDED` results count toward neither numerator nor
   denominator (§15B's under-risking carve-out). Total R: sum `rMultiple` across Step 3's
   `get_recent_trades` results. Session completeness: the Step 2 count (e.g. "4 of 5 days
   complete").
4. **Resolve this week's missed-opportunity hypotheticals** (§16) — TARGET (would-have-won) /
   STOP (would-have-lost) / still-genuinely-PENDING (leave alone, don't force a resolution the
   data doesn't support) via `resolve_hypothetical`. Track as statistics, not narrative.
   - For each **triggered** hypothetical, check Step 3's calendar events — if the trigger fell
     inside a §6 event window, resolve it `BLOCKED` instead of `TARGET`/`STOP`. The trade could
     not have been taken regardless of its R:R.
   - Where chart resolution is genuinely insufficient to tell honestly, resolve `UNRESOLVED` and
     state what data would settle it (ask the pilot rather than guess) — never mark won/lost on a
     guess.
   - **Break the aggregate down by instrument, not just in total.**
5. **Compare executed R per trade against skipped R per hypothetical.** State the sample size
   explicitly and why it limits the conclusion — this is not enough data to prove the rules are
   too tight or too loose off one week.
6. **Tally the rejection-reason counter (§15C)** — for every setup considered and rejected this
   week, which checklist item killed it? Read Step 3's `checklistReasoning` text per day to
   attribute. This is diagnostic, not a score — a high count on one item may be the rules working
   correctly, not a problem.
7. **Flag (do not adopt)** anything worth raising at the next quarterly review — add it to
   `CLAUDE.md` §21.3 with the evidence that prompted it, same as any other session per §20.14.

## Step 5 — write through MCP (the only write path)

1. **`resolve_hypothetical`** — once per hypothetical resolved in Step 4.4.
2. **`write_journal_rollup`** — `period: "weekly"`, this week's `periodKey`. Set `overviewMd`
   (Steps 4.1–4.2 + the rejection-reason tally from 4.6, as prose/markdown — there's no dedicated
   structured field for the tally, matching §15C's own framing as "a diagnostic, not a scored
   metric"), `reflectionMd` (Step 4.5's executed-vs-skipped comparison and its sample-size
   caveat), `complianceOverall`/`complianceVerdict`/`complianceExecution` (Step 4.3),
   `totalR` (Step 4.3). **Do not set `weekAheadScanMd`** — that belongs to `week-start`, and the
   upsert leaves it untouched as long as this call doesn't include it.

If any call fails partway through, stop and report exactly what succeeded and what didn't —
including which hypotheticals were actually resolved before a failure, if one happens mid-loop.

## What this does NOT do

Same constraints as the old protocol: this does not resolve or score today's or any other week's
hypotheticals beyond this one — that stays each week's own job. This does not propose rule changes
directly to CLAUDE.md — only §21.3 gets a flag, per §20.14; adoption only happens at `quarter-end`.
