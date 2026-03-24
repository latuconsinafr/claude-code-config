---
name: debug
description: Use when you encounter a bug, error, or unexpected behavior during a task — follows a reproduce → isolate → fix → verify cycle. Invoke this instead of guessing at a fix.
allowed-tools: Read, Grep, Glob, Bash
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

## Step 2: Reproduce

Establish a reliable way to reproduce the issue before touching any code.
```bash
# Run the failing test
# Invoke the failing command
# Check current logs
```

**If you cannot reproduce it:**
- Check `git log --oneline -10` — was this broken by a recent commit?
- Check if the issue is environment-specific (env vars, versions, OS)
- Add structured logging to the suspected code path and re-run
- Consider `git bisect` to find the commit that introduced it:
  ```bash
  git bisect start
  git bisect bad HEAD
  git bisect good <last-known-good-commit>
  # then test and mark each step
  ```
- Do not guess at a fix for an unreproduced issue — state this explicitly.

## Step 3: Isolate

Narrow down the root cause using the issue category from Step 1:

**For all types:**
- Read the full stack trace — start from the bottom (innermost frame)
- Find the exact line where behavior diverges from expectation
- Check recent changes in the affected area: `git log --oneline -10 -- <file>`
- Check for similar patterns elsewhere in the codebase that work correctly

**For runtime/logic errors:**
- Trace the data flow from input to the failure point
- Check for null/undefined at each step
- Form a testable hypothesis (see below)

**For performance issues:**
- Identify the slow operation (query, loop, I/O call)
- Check if it's N+1 (query in a loop), missing index, or blocking I/O
- Measure before optimizing — don't optimize based on assumption

**For intermittent/race conditions:**
- Look for shared mutable state
- Look for async operations without proper awaiting or locking
- Look for timing-dependent assumptions

**For environment-specific issues:**
- Diff the environment variables between working and failing environments
- Check dependency versions (`package.json`, lockfile, language runtime version)

**Structured hypothesis:**
Before attempting a fix, state your hypothesis explicitly:
```
Hypothesis: <what I believe is wrong>
Evidence: <what in the code/logs supports this>
Prediction: <what will happen if my hypothesis is correct>
Test: <how I will verify or falsify this>
```
If you cannot fill in all four fields, keep investigating — you don't have a hypothesis yet.

## Step 4: Fix

Make the **minimal change** that fixes the root cause.
- Do not fix symptoms — fix the cause
- Do not refactor unrelated code while fixing
- Add a comment if the fix is non-obvious: `// Fix: <why this is necessary>`

## Step 5: Verify

**a. Write a regression test first** — before confirming the fix works:
```bash
# Write a test that fails with the bug present
# Then confirm the fix makes it pass
```
A fix without a regression test is incomplete. The test documents the bug and prevents recurrence.

**b. Run the test suite:**
```bash
# Run tests covering the affected area
# Run the full suite to check for regressions
```

**c. Re-run the original reproduction case** — confirm the specific issue is gone.

## Step 6: Output

Summarize:
- **Root cause**: what was actually wrong and why
- **Fix**: what was changed and the reasoning
- **Regression test**: what test was added and what it covers
- **Verification**: test output confirming the fix
- **Follow-up**: tech debt, missing tests elsewhere, related risk areas to watch
