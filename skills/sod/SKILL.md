---
name: sod
description: Run the Start-of-Day analysis and verdict session for the trading journal (CLAUDE.md Section 11, at /Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md). Global, MCP-only — writes exclusively to the trading-journal MCP server, no markdown output. Auto-detects today's date, asks for the pilot's thesis, then runs the full daily protocol. Invoke every trading morning.
allowed-tools: Read, Edit, Bash, Glob, mcp__trading-journal__*
---

# Daily Analysis — Start of Day (global, MCP-only)

**This skill replaces the old project-local `/sod`** (formerly at
`Journals/.claude/skills/sod/`, deferring to `Journals/PROMPTS.md`). That file and its
markdown-writing sibling files are left in place, unused — this skill does not read or write
any of `journal/`, `metrics/`, `account/`, or `PROMPTS.md`. The session protocol below is now
owned by this file directly, since nothing else reads `PROMPTS.md` to keep it in sync anymore.

**What still has one source of truth:** `CLAUDE.md` at
`/Users/latuconsinafr/Personal/Trading/Journals/CLAUDE.md` remains the actual rulebook —
Section numbers referenced below (§3, §5, §6, §7, §8, §9, §15, §16, §19) point there. Read it in
full if it hasn't been read yet this session. `trading_rules` (the DB table meant to eventually
hold this content structurally) is empty as of 2026-08-18 — porting CLAUDE.md's 21 sections into
structured rows correctly is its own high-stakes task, not something to do casually here. Until
that exists, this file keeps reading CLAUDE.md directly rather than trusting an empty table.

**If anything this session suggests a rule should change**, per CLAUDE.md §20.14: add it to
CLAUDE.md §21.3 (a short row in the parked-observations table) — **do not act on it.** Rule
changes belong at quarter boundaries (§13). This is the one legitimate edit this skill makes to
CLAUDE.md itself; nothing else in this file writes to it.

**Instrument code mapping — required for every MCP call below, verified empirically 2026-08-18.**
CLAUDE.md and this file use the shorthand EU/GU/UJ/XAU throughout for readability, but every MCP
tool's `instrument` parameter is a full pair-code enum (`EURUSD`, not `EU`) — confirmed by an
actual rejected call during this skill's own smoke test. Translate before every call:

| Shorthand | MCP `instrument` value |
|---|---|
| EU | `EURUSD` |
| GU | `GBPUSD` |
| UJ | `USDJPY` |
| XAU | `XAUUSD` |

## Step 0 — confirm the MCP server is actually reachable

**Do this before anything else.** There is no markdown fallback anymore — if the MCP server is
down, nothing from this session can be recorded at all. Call `get_account_state` (cheap, no
side effects) as a connectivity check.

- **Succeeds** → proceed.
- **Fails** → stop. Tell the pilot plainly: the `trading-journal` MCP server isn't reachable,
  likely because the production stack isn't running (`just run` in `webapp/`, which builds the
  app and brings up the Cloudflare tunnel together). Ask whether to wait while they start it and
  retry, or proceed analysis-only with an explicit, repeated warning that nothing said in this
  session will be saved anywhere. Never silently proceed as if recording will happen when it
  won't — that's the exact hindsight/reconstruction failure mode CLAUDE.md §18 exists to prevent,
  just in a new shape.

## Step 1 — resolve the date

Use today's system date, unless the pilot gives one explicitly.

**Hard guard: refuse any date before today.** This skill writes a directional thesis, and a
thesis for a day that already happened is being written with knowledge of what the market
actually did — worse than no record, because it looks genuine. If asked for a past date, say
plainly that SOD cannot run for it, and point to `/eod [DATE]` instead — reviewing what happened
is legitimate; inventing what would have been thought is not. A future date is fine (pre-planning
ahead of a known gap) but flag that it needs re-confirming against same-day charts before
anything is actually traded on it.

## Step 2 — load context via MCP, not files

No `account/account_spec.md` or `account/trading_conventions.md` to read — that content now
lives in the DB and is the whole reason those files are being left behind. Call:

- **`get_account_state`** — balance, sizing phase, cumulative deposited, hard-stop threshold.
- **`get_trading_conventions`** — the declared breakeven/partial/trailing convention in force.
  Required before approving any entry (CLAUDE.md §20.10) — never assume which one is active.
- **`get_trading_rules`** — will return empty today (see header note); call it anyway so this
  starts working automatically once that table is populated, with no skill change needed.
- **`get_open_positions`** and **`get_session_completeness`** (recent) — continuity context, so
  today's read isn't blind to what's already open or how recent sessions went.

## Step 3 — locate today's charts

Charts are filed by **when they were captured** — today, always — not by which entry they
inform. Check, in order:

1. **`charts/[DATE]/`** (flat) — the normal case, one capture serving both SOD and EOD if this
   runs inside `/evening`.
2. **`charts/[DATE]/sod/`** — if SOD and EOD are being captured separately this session.

- **All 12 found** (D1/H4/M15 × EU/GU/UJ/XAU) → read them directly, don't ask the pilot to
  re-attach anything.
- **Some found, some missing** → name exactly which are missing, ask only for those.
- **None found, and none pasted this turn** → ask the pilot to paste the 12 clean charts.
  Pasted images resolve to a real local path when Claude Code and the trading.db/webapp are on
  the same machine (confirmed empirically 2026-08-18) — `attach_chart` in Step 6 uses that path
  directly. **If Claude Code is running on a different machine than the one hosting the MCP
  server**, a pasted image's local path won't be readable by the server — if `attach_chart` fails
  for this reason, say so plainly rather than silently skipping the attachment.
- **Annotated versions also present** → set them aside. Read the clean charts first and
  independently, before looking at annotated ones or the pilot's stated thesis — this ordering
  is deliberate (see Step 5.1); skipping it means anchoring to the pilot's markup instead of
  forming an independent read.

**Optional, separate from the required 12 — heatmap prep, not a §2 change.** CLAUDE.md §2's
daily-reviewed timeframes (D1/H4/M15) are unaffected by this and stay exactly as written; this is
capture for a different, not-yet-built feature (the dashboard heatmap's real technical scores —
see `webapp/TODO.md`). If a 1H clean chart per instrument is available (`charts/[DATE]/{SYMBOL}H1.png`,
matching the existing `{SYMBOL}Daily/H4/M15.png` convention — `{SYMBOL}` being the full pair code
per the mapping table above, e.g. `EURUSDH1.png`), note that it's on disk for later use. **Do not
ask the pilot to capture it and do not block the session on it** — no write tool consumes it yet
(`write_technical_score` doesn't exist), so asking for it today would be session overhead for a
feature with no payoff. Revisit this note once that tool exists; then this becomes a real ask.

## Step 4 — get the pilot's thesis

Ask once, plainly: *"What's your thesis for each instrument today?"* — and wait. **Do not
proceed without it and do not offer one first.** CLAUDE.md §1 is absolute: Claude never
originates the first directional call, for any instrument, ever.

## Step 5 — run the analysis, in this exact order

1. Using ONLY the clean charts, state an independent structural read per instrument (D1
   structure → H4 confirmation → M15 timing) — **before** reacting to the pilot's thesis or any
   annotated chart. For every level named, state WHERE PRICE PREVIOUSLY TURNED there (date +
   wick) — CLAUDE.md §3.3's validation test. If it can't be named, call it a price, not a level.
   Note volume where it confirms or contradicts a break, rejection candle, or trend (§3.10,
   observational, not pass/fail).
2. Compare against the pilot's thesis (and annotated charts, if attached). Apply the full §3
   checklist — support, challenge, or flag gaps. Explicitly check the pilot's levels against the
   same standard: prior turn named, zone width within the §3.6 max, and whether the target is the
   FIRST obstacle or a later one (§3.7).
3. Run today's fundamental digest (§4): calendar events, currency strength 0–10 for USD/EUR/GBP/
   JPY, XAU risk-sentiment read. §19 sources only — release times/dates from the issuing
   institution, never a summary article. State times in WIB / server / ET.
4. Apply correlation/clustering (§5), event-risk timing (§6), and the conflict-resolution table
   (§7).
5. Give a verdict per instrument: enter now / pending limit-stop order / wait for [condition] /
   stand aside / skipped — with reasoning. `SKIPPED` needs a stated reason; there's no
   `NOT_ANALYZED` case here since all four instruments always get *some* verdict in normal
   operation.
6. If wait/stand-aside: the hypothetical gets logged live in Step 6, not reconstructed later.
   Where a setup fails §3.7, it gets logged **twice** — once at the wanted target, once at the
   actual obstacle (§16).
7. If entering now, in-session: confirm minimum 1:2 R:R, check drawdown circuit breakers (§9),
   size per §8, state the management convention up front. If entering **later**, outside this
   session (the normal case), point to the Pre-Trade Check per Step 7 below — the record must
   exist before the click, not after.

## Step 6 — write the session through MCP (the only write path)

**No markdown, no "additive" fallback — this is the record.** If any call in this list fails
partway through, stop and report exactly which calls succeeded and which didn't, rather than
silently treating the session as fully recorded. Never invent values to fill an argument — every
call here uses values that actually came out of Step 5.

1. **`write_daily_analysis`** — once per instrument, all four, every day, including a `SKIPPED`
   verdict with a `skipReason` if one was deliberately not reviewed.
2. **`write_fundamental_digest`** — once per currency (USD/EUR/GBP/JPY).
3. **`write_risk_sentiment`** — the XAU risk-sentiment read (different scale from currency
   strength — don't conflate the two calls).
4. **`write_calendar_event`** — for each relevant event surfaced this session. Leave `timeUtc`
   unset and say so if it isn't verified against a primary source.
5. **`write_hypothetical`** — for any wait/stand-aside verdict, live. Double-log per §16 where a
   setup failed §3.7.
6. **`write_level`** — for any level named today that isn't already on file, or whose prior turns
   changed. Check with `get_active_levels` first — this is a plain insert, so calling it for an
   existing level creates a duplicate rather than updating it.
7. **`attach_chart`** — once per screenshot actually read this session (up to 12), by the path it
   was read from in Step 3. Never re-paste an image just to attach it. If the path isn't readable
   by the MCP server (cross-machine case, see Step 3), say so rather than silently skipping.
8. **`mark_session`** — `sodDone: true` for today's date.

## Step 7 — the Pre-Trade Check

If any verdict is "enter now" or produces a level to watch for later entry, point the pilot to
the webapp's **`/trades/new`** (`https://trading.latuconsinafr.com/trades/new` if the tunnel is
up, otherwise whatever local URL is reachable this session) — it runs the same §15/§9 gate,
computes R:R and lot size live, and writes a real `OPEN` trade plus the compliance checklist
snapshot when submitted.

**`open_trade` (the MCP tool) is import/backfill only — never call it to represent a live entry.**
If asked to "record" or "log" a trade the pilot says they just placed, decline and point to
`/trades/new` instead. This is a settled decision (2026-08-18), not a judgment call to re-litigate
per session.
