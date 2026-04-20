---
name: debug
description: Use when you encounter a bug, error, or unexpected behavior during a task — follows a reproduce → isolate → fix → verify cycle. Invoke this instead of guessing at a fix.
allowed-tools: Agent, Read, Grep, Glob, Bash
---

# Debug

Systematically debug the problem described in `$ARGUMENTS`.
Do not guess. Do not fix without reproducing first.

## Step 1: Understand and categorize the problem

Parse `$ARGUMENTS` for:
- What is the observed behavior?
- What is the expected behavior?
- Is there an error message or stack trace?
- When did this start? After what change?

If critical information is missing, ask for it before proceeding.

**Categorize the issue type** — the investigation strategy depends on this:
- **Runtime error** — exception, crash, panic, unhandled promise rejection
- **Logic error** — wrong output, incorrect calculation, unexpected state
- **Performance** — slow response, high CPU/memory, timeout
- **Intermittent** — flaky, race condition, timing-dependent
- **Environment-specific** — works locally, fails in CI/staging/production
- **Build/type error** — compilation failure, type mismatch, import error

## Step 2: Investigate — spawn the `debugger` agent

Spawn the `debugger` agent to investigate in isolation. This keeps debug artifacts out of the main context and uses the agent's systematic root cause methodology.

Pass the following as the agent task:
```
Bug report: <observed behavior from Step 1>
Expected behavior: <expected behavior from Step 1>
Issue category: <category from Step 1>
Error/stack trace (if any): <paste here>
Reproduce with: <failing test command or steps>
```

The `debugger` agent will return:
- Root cause with evidence and location (`file:function:line`)
- Proposed minimal fix
- Class of bug — other locations in the codebase with the same assumption
- Detection gap — what would have caught this sooner

**If the agent cannot reproduce the issue:** do not guess. Surface the agent's findings to the user and ask for more context (environment details, additional logs, or a more specific reproduction case).

## Step 3: Apply the fix

Review the root cause and proposed fix from the `debugger` agent.

Make the **minimal change** that fixes the root cause — not the symptom:
- Do not fix multiple things in one commit
- Do not refactor unrelated code while fixing
- Add a comment if the fix is non-obvious: `// Fix: <why this is necessary>`

Also check the "class of bug" output — if other locations share the same flawed assumption, fix those too (or note them as follow-up).

## Step 4: Write a regression test — spawn the `qa` agent

Spawn the `qa` agent to write the regression test. Pass:
```
Bug fixed: <one-sentence description of the root cause>
Fix location: <file:line of the fix>
Reproduce with: <the reproduction case from Step 2>
```

The test must:
- Fail with the bug present (verify this before the fix)
- Pass after the fix
- Document *why* it exists (describe the bug it prevents in the test name or comment)

A fix without a regression test is incomplete.

## Step 5: Verify

```bash
# Run the regression test to confirm it passes
# Run tests covering the affected area
# Run the full suite to check for regressions
# Re-run the original reproduction case — confirm the issue is gone
```

## Step 6: Output

Summarize:
- **Root cause**: what was actually wrong and why
- **Fix**: what was changed and the reasoning
- **Regression test**: what test was added and what it covers
- **Verification**: test output confirming the fix
- **Follow-up**: class-of-bug locations to check, tech debt, missing detection gaps
