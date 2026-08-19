---
name: six-month-checkpoint
description: Run the one-time Six-Month Checkpoint for the trading journal (CLAUDE.md Section 17, at /Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md) — the primary evaluation point for this trading practice. Global, MCP-only — writes exclusively through the trading-journal MCP server, no markdown output. Reports the full-period compliance trend (the primary metric), the R-multiple trend (secondary), and lays out the continue/adjust/pause/stop options without pushing toward any one of them. Invoke once, at the six-month mark, regardless of quarter alignment.
allowed-tools: Read, Edit, Bash, Glob, mcp__trading-journal__*
---

# Six-Month Checkpoint (global, MCP-only)

**Replaces the old project-local `/checkpoint`** (now archived at
`Journals/.claude/skills-legacy/checkpoint/`). `CLAUDE.md` at
`/Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md` remains the rulebook — §17 is this
session's actual mandate.

**This is a one-time session, unlike every other skill in this set.** Check whether it's already
run (Step 1) before doing anything else — running it twice would produce two different
`journal_rollups` rows with `period: "checkpoint"` (each keyed by the date it ran, since there's
no recurring `periodKey` for a one-time event), which would be confusing, not catastrophic, but
still worth avoiding.

**If anything this session suggests a rule should change**, per CLAUDE.md §20.14: add it to
CLAUDE.md §21.3, do not act on it — this skill does not have `quarter-end`'s rule-adoption
authority, even though it's a major evaluation point.

## Step 0 — confirm the MCP server is reachable

Call `get_account_state` first. If it fails, stop and explain `just run` needs to be running.

## Step 1 — confirm the date and check for a prior run

Day 1 of this practice was **2026-08-04**; the six-month mark is approximately **2026-02-04**.
Verify precisely against the deposit ledger (Accounts page, `/accounts`, first deposit date) —
this checkpoint's value depends on being run at the actual mark, not adjusted to convenience. If
invoked meaningfully early or late, say so plainly before proceeding.

Call **`get_journal_rollups`** (`period: "checkpoint"`, `limit: 1`). If a row already exists,
confirm with the pilot before running it again rather than silently producing a second one.

## Step 2 — gather the full period (not a single cascade level)

**This is the one skill in the whole set that does NOT read just one level below.** It pulls
across the *entire* six months:

- **`get_journal_rollups`** (`period: "quarterly"`, generous `limit`, e.g. 6) — every quarterly
  review that's actually complete within the period.
- **For the trailing partial quarter** (the current one, not yet reviewed by `quarter-end` since
  it hasn't finished) — **`get_journal_rollups`** (`period: "monthly"`, recent `limit`) instead,
  for whatever months of it are actually complete. This is the §13 drill-down fallback applied
  deliberately, not a shortcut: there is no quarterly rollup yet for a quarter still in progress,
  so the next level down is the honest source for that portion.
- **`get_hypotheticals`** — `dateFrom` = 2026-08-04, `dateTo` = the checkpoint date, no status
  filter (this is the tool that exists specifically because `get_pending_hypotheticals` can't see
  resolved ones) — the full missed-opportunity aggregate needs every hypothetical from the whole
  period, not just what's still open.
- **`get_session_completeness`** with a `limit` large enough to span the whole period, for the
  session-completeness series.

## Step 3 — run the checkpoint, in this order

1. **Report the process compliance % trend over the full period — this is the primary metric
   (§17).** Report verdict, execution, and session completeness as three separate series, drawn
   from Step 2's quarterly/monthly rollups (average the rates across the period, same convention
   every other `-end` skill in this set uses).
2. **Report the R-multiple expectancy trend — secondary and informational only.** Sum `totalR`
   across Step 2's rollups. Explicitly flag the sample size (how many trades this actually
   represents) and why it limits how much this can be trusted as evidence of edge either way —
   six months is not enough data to prove or disprove an edge on its own.
3. **Report the missed-opportunity aggregate alongside it** — from Step 2's `get_hypotheticals`
   pull: did the rules cost more than they saved, broken down **by instrument**, not just in
   total.
4. **Answer honestly: was the process followed consistently?** What broke down, if anything, and
   when — cite specific weeks/months by name, not general impressions. This is the actual
   question §17 asks; do not let a good or bad R-multiple number color the answer either way.
5. **Lay out the options plainly** — continue as-is, continue with quarter-boundary adjustments,
   pause, or stop — **without pushing toward any one of them.** This is the pilot's decision, not
   Claude's to steer.

## Step 4 — write through MCP (the only write path)

**`write_journal_rollup`** — `period: "checkpoint"`, `periodKey` = today's actual date (e.g.
`"2027-02-04"`). `overviewMd` (Step 3.1–3.3, the three-series compliance report plus the
missed-opportunity aggregate), `reflectionMd` (Step 3.4's honest answer plus Step 3.5's options,
laid out without a recommendation baked in), `complianceOverall`/`complianceVerdict`/
`complianceExecution` (Step 3.1), `totalR` (Step 3.2).

If the call fails, stop and report it — the checkpoint conversation itself already happened and
has real value even if the write fails; say so rather than implying the whole session needs
redoing.

## The one thing to get right

This is §17's primary evaluation point: *"did process compliance stay consistently high across
the period?"* — not profitability, not win rate. If the R-multiple numbers are good, that is not
permission to undersell the compliance trend, and if they're bad, that is not permission to
oversell it either. Both get reported straight; the pilot decides what they mean.
