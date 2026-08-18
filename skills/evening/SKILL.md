---
name: evening
description: Run EOD + SOD together for the trading journal — the pilot's actual nightly routine. Global, MCP-only, composes the global sod and eod skills. Invoke every evening instead of running them separately.
allowed-tools: Read, Edit, Bash, Glob, mcp__trading-journal__*
---

# Evening Session — EOD + SOD together (global, MCP-only)

**Replaces the old project-local `/evening`.** Composes `sod/SKILL.md` and `eod/SKILL.md` (both
now global, MCP-only) — it does not duplicate their content, and does not read or write
`journal/`, `metrics/`, `account/`, or `PROMPTS.md`. `CLAUDE.md` at
`/Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md` remains the rulebook.

**Why the order matters and why the dates differ:** a SOD verdict written tonight (~21:00)
governs trading through tomorrow night's session. So the EOD half of tonight's sitting closes out
a **different, earlier calendar date** than the SOD half opens. Running EOD before SOD also means
tonight's fresh verdict is informed by how the prior one actually played out.

**Instrument code mapping** — this file uses EU/GU/UJ/XAU shorthand like CLAUDE.md does, but any
MCP call (made via the composed `sod`/`eod` steps below) needs the full pair code: EU → `EURUSD`,
GU → `GBPUSD`, UJ → `USDJPY`, XAU → `XAUUSD`. See `sod/SKILL.md`'s header for how this was found
(a rejected call during its own smoke test, 2026-08-18).

## Step 0 — check what day it actually is

**The forex market is closed Saturday and most of Sunday.**

- **Saturday** → no evening session. Point to `/week-end` if that week hasn't been closed out
  yet. Stop.
- **Sunday** → no evening session — Friday's flatten closed everything and nothing has traded
  since, so there's no fresh EOD and no live chart for a SOD verdict. Point to `/week-start`.
  Stop. *(Market typically reopens Sunday evening ET, roughly Monday 04:00–05:00 WIB — confirm
  against MT5 rather than assuming; brokers vary.)*
- **Friday** → proceed, but see the Friday handling in Step 4 — the SOD half is constrained,
  not skipped.
- **Monday–Thursday** → proceed normally.

## Step 1 — check for a §6 event window right now

Check current WIB time against any known red-folder releases already surfaced this session. If
inside a §6 window, note it — informational, blocks new order placement only, not analysis or
review.

## Step 2 — gather charts ONCE, for both halves together

**Screenshot once per session, not once per half.** The EOD review and tonight's SOD both read
the market at the same moment, so one set of charts covers both.

Charts are filed by **when captured — today — never by which entry they inform.** The EOD half
is about an earlier date (`[PENDING]`), but tonight's charts still live under today's folder.

In practice: the SOD half unconditionally needs all 12 (D1/H4/M15 × EU/GU/UJ/XAU per
`sod/SKILL.md` Step 3), which already covers whatever conditional M15 subset the EOD half needs
(open position, pending order, active "wait for level", or a red-folder day on `[PENDING]`) — so
**just ask for the full 12-chart set once.**

Check `charts/[TODAY]/` (flat) on disk first per the same convention as `sod/SKILL.md` Step 3;
ask only for whatever's genuinely missing. State plainly that tonight's charts are being used to
review an earlier date, so the capture-date/review-date gap is honest in the record.

## Step 3 — run the pending EOD(s), mark anything genuinely missed

Follow `eod/SKILL.md` Step 0 (MCP connectivity check) and Step 1 exactly — it scans the full gap
via `get_session_completeness`, not just one date, splitting it into PENDING (real reviews,
oldest-first) and MISSED (no protocol, no thesis, ever — `eod/SKILL.md` Step 5). Use tonight's
charts (Step 2 above) for every PENDING review in the gap.

- **Nothing in the gap** → say so, move to Step 4.
- **PENDING days** → run each in full via `eod/SKILL.md` Steps 2–7, oldest first.
- **MISSED days** → mark per `eod/SKILL.md` Step 5. Common after exactly the scenario `/evening`
  exists to prevent — not a failure of this skill, it's correctly refusing to invent what didn't
  happen.

## Step 4 — run tonight's SOD

Follow `sod/SKILL.md` Steps 1–7 exactly, using **today's actual calendar date** and the charts
already gathered in Step 2 — the one place in this combined session where "today" is the correct
default, since tonight's verdict governs trading forward.

### If today is Friday — run the analysis, but state the constraint before the verdict

CLAUDE.md §18 still requires a journal entry — **do not skip the SOD half.** State plainly,
before running the checklist, that §10 requires everything flat by ~04:00 WIB Saturday (≈7 hours
from a 21:00 session), and a framework built on higher-timeframe structural entries has no setup
sized for a 7-hour hold. **The expected outcome is stand-aside on every instrument** — reached
because the checklist genuinely returns it, not asserted in place of running it.

**As part of this same session, not deferred to Monday:**
- Close any open position manually at market (via `close_trade` once actually closed in the
  broker platform — this skill has no live order access, same as everywhere else) — don't leave
  it to hit stop or target over the weekend.
- Confirm every resting order gets cancelled in the broker platform.
- Confirm no new order will be placed tonight, regardless of what the analysis finds.

Log missed-opportunity hypotheticals as normal for whatever verdict the checklist produces —
data collection continues on Fridays same as any other day.

## Step 5 — orders and the Pre-Trade Check

If Step 4 produces an "enter now" verdict or a level to watch, follow `sod/SKILL.md` Step 7 —
point the pilot to the webapp's `/trades/new`. The compliant entry style is a resting limit
placed tonight, not a market order during work hours — the Pre-Trade Check exists before the
order rests, not when it fills.

## Step 6 — close out

Confirm, via MCP reads (not file checks): **`get_session_completeness`** shows `eodDone: true`
for the closed-out `[PENDING]` date(s) and `sodDone: true` for today. Confirm every write in
`eod/SKILL.md` Step 7 and `sod/SKILL.md` Step 6 actually landed — if any call failed partway
through either half, say so explicitly rather than treating the night as fully recorded.

Once this session is closed out, it's over — no re-checking charts before tomorrow's 21:00.
