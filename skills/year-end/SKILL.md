---
name: year-end
description: Run the Yearly Review for the trading journal (CLAUDE.md Section 13, at /Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md). Global, MCP-only — writes exclusively through the trading-journal MCP server, no markdown output. Full aggregation of compliance % and R-multiple trend across the year, reflecting against the six-month checkpoint's conclusions. Invoke at year close, after that year's quarterly reviews are done.
allowed-tools: Read, Edit, Bash, Glob, mcp__trading-journal__*
---

# Yearly Review (global, MCP-only)

**Replaces the old project-local `/year-end`** (now archived at
`Journals/.claude/skills-legacy/year-end/`). `CLAUDE.md` at
`/Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md` remains the rulebook.

**If anything this session suggests a rule should change**, per CLAUDE.md §20.14: add it to
CLAUDE.md §21.3, do not act on it — this skill does not have the rule-adoption authority
`quarter-end` has.

## Step 0 — confirm the MCP server is reachable

Call `get_account_state` first. If it fails, stop and explain `just run` needs to be running.

## Step 1 — resolve the year and find its quarters

Use the current year, unless the pilot gives one explicitly. A year is exactly 4 quarters — no
boundary ambiguity.

Call **`get_journal_rollups`** (`period: "quarterly"`, `limit: 4`). Confirm all four quarters of
this year have a row. **If any is missing, note the gap explicitly — do not backfill it.**

## Step 2 — check whether the six-month checkpoint is due

Day 1 of this practice was **2026-08-04**; the six-month mark is approximately **2026-02-04**.
Verify precisely against the deposit ledger (Accounts page, `/accounts`) rather than trusting this
approximation — the checkpoint's own restatement of the date is what actually governs it. **If
that mark falls inside this year and `checkpoint` hasn't been run yet, flag it plainly** — the
checkpoint is a separate one-time session, and should not be folded into this yearly review even
if the dates are close.

## Step 3 — run the review

1. **Full aggregation of compliance % and R-multiple trend across the year** — from Step 1's four
   quarterly rollups. Same convention as `month-end`/`quarter-end`: compliance fields averaged
   (already rates), `totalR` summed (additive).
2. **Full-year reflection** — what changed, what was learned, and (if the checkpoint has already
   run by this point) whether its conclusions held up over the full year. If the checkpoint
   hasn't run yet, this comparison isn't possible — say so rather than guessing at what it might
   have concluded.

## Step 4 — write through MCP (the only write path)

**`write_journal_rollup`** — `period: "yearly"`, this year's `periodKey` (`"2026"`). `overviewMd`
(Step 3.1's aggregate), `reflectionMd` (Step 3.2's full-year reflection), the three compliance
fields and `totalR` from Step 3.1.

If the call fails, stop and report it rather than treating the review as recorded.
