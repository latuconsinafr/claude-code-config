---
name: quarter-end
description: Run the Quarterly Review for the trading journal (CLAUDE.md Section 13, at /Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md) — the ONLY point in the cycle where core rule changes (Section 3 checklist, Section 8 risk %, Section 5 correlation cap, Section 6 event window) may be proposed and adopted. Works through every item parked in CLAUDE.md Section 21.3. Global, MCP-only for the review data; the one skill in this set with Edit access to CLAUDE.md itself. Invoke at quarter close, after that quarter's monthly reviews are done.
allowed-tools: Read, Edit, Bash, Glob, mcp__trading-journal__*
---

# Quarterly Review (global, MCP-only) — the one session allowed to change CLAUDE.md

**Replaces the old project-local `/quarter-end`** (now archived at
`Journals/.claude/skills-legacy/quarter-end/`). `CLAUDE.md` at
`/Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md` remains the rulebook — and this is the
**one session in the whole cycle where the source of truth itself is allowed to change.** Treat
that as reason for *more* care here, not less. Every other skill in this set — including this
one, outside this specific step — refuses to touch CLAUDE.md beyond appending an observation to
§21.3.

## Step 0 — confirm the MCP server is reachable

Call `get_account_state` first. If it fails, stop and explain `just run` needs to be running.

## Step 1 — resolve the quarter and find its months

Use the current `YYYY-Qn`, unless the pilot gives one explicitly. A quarter is exactly 3 calendar
months (Q1=Jan–Mar, Q2=Apr–Jun, Q3=Jul–Sep, Q4=Oct–Dec) — no boundary ambiguity like weeks-into-
months has.

Call **`get_journal_rollups`** (`period: "monthly"`, `limit: 4`). Confirm all three months of this
quarter have a row. **If any is missing, that month's `month-end` was never run — do not backfill
it, note the gap explicitly**, same principle as every other level in this set.

## Step 2 — pull the full parked list

**Read `CLAUDE.md` §21.3 in full** (the file itself, not a paraphrase — this table is the complete
list of everything flagged since the last quarterly review, and nothing gets adopted that isn't
on it with evidence already attached). A rule change proposed for the first time in this session,
with no prior observation trail in §21.3, **does not belong here** — it goes into §21.3 instead
and waits for the *next* quarterly. This is CLAUDE.md's own explicit rule (§13, §18, §21.1), not
a preference — see "The one rule this skill exists to protect" at the bottom of this file.

## Step 3 — run the review

1. **Aggregate compliance % and R-multiple trend for the quarter** — from Step 1's three monthly
   rollups. Same convention as `month-end`: compliance fields averaged (already rates), `totalR`
   summed (additive).
2. **Review what setups worked and didn't**, and revisit everything flagged in the past three
   monthly reviews (Step 1's rollups' `overviewMd`/`reflectionMd`).
3. **Work through §21.3 item by item — adopt, reject, or defer, with the reason recorded for
   each.** See Step 4 below for exactly how each outcome gets written.
4. **This is the ONLY point where core rule changes (§3 checklist, §8 risk %, §5 correlation cap,
   §6 event window) may be formally proposed and adopted.** Discuss each explicitly and decide —
   do not carry a silent change forward, and do not change anything outside this session that
   wasn't already sitting in §21.3.
5. **Re-confirm the trade-management convention for the coming quarter.** Read the current one
   via `get_trading_conventions`. If it's changing, point the pilot to the Accounts page
   (`/accounts`, "Declare a new convention") — conventions are declared through that form, not
   written by this skill directly, same "real declarations go through the web form" pattern as
   trades and deposits. If it's *not* changing, still state that explicitly — carrying forward
   silently is exactly what this step exists to prevent.

## Step 4 — how each §21.3 item actually gets resolved

For every item worked through in Step 3.3:

- **Adopted** → make the actual rule change in its home section of `CLAUDE.md` (Edit tool, the
  real file) — this is the only kind of edit this skill makes to the rule text itself. Add a row
  to **§21.2** (the amendment log: `Date | Sections | Change | Basis`) recording what changed and
  why. Remove the item from §21.3 — it's no longer parked, it's adopted.
- **Rejected** → remove the item from §21.3. The decision and reasoning are **not** a CLAUDE.md
  edit (§21.2 is an amendment log — only actual rule changes belong there, per its own purpose) —
  record the rejection and why in this quarter's `reflectionMd` (Step 5) instead, so the reasoning
  isn't lost, just not mixed into the rulebook itself.
- **Deferred** → leave it in §21.3, but update its `Evidence`/`Status` columns with whatever this
  quarter added (more instances observed, more data gathered, etc.) — don't leave stale evidence
  sitting under a status that no longer reflects what's actually known.

**Do not make an exception because the reasoning "seems obviously right this time."** A rule
change proposed mid-review that wasn't already on the §21.3 list gets *added* to §21.3 and waits
for the next quarterly — exactly like a mid-quarter proposal would. That's the pressure this
whole lock exists to resist, and it applies inside this session just as much as outside it.

## Step 5 — write through MCP (the only write path for the review itself)

**`write_journal_rollup`** — `period: "quarterly"`, this quarter's `periodKey` (`"2026-Q3"`).
`overviewMd` (Step 3.1–3.2), `reflectionMd` (Step 3.3's outcomes — what was adopted/rejected/
deferred and why, including every rejected item's reasoning per Step 4), the three compliance
fields and `totalR` from Step 3.1.

If this call fails, stop and report it — but note that any CLAUDE.md edits from Step 4 already
happened and are real regardless; don't imply the whole session needs redoing if only this last
write fails.

## The one rule this skill exists to protect

Every other skill in this project refuses to touch `CLAUDE.md`. This is the single exception, and
only for what's already sitting in §21.3 with evidence. If a rule change is suggested mid-quarter
— including during this very session, for something *not* on the parked list — it gets added to
§21.3 and waits for the next quarterly, per §13's own logic. **A rule that costs money mid-quarter
is not grounds for amending it mid-quarter either** — that's precisely the pressure §13 was
written to resist, and it doesn't get weaker just because this session is the one with edit
access.
