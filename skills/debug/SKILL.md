---
name: debug
description: Systematically debug a bug, error, or unexpected behavior. Follows a structured reproduce-isolate-fix-verify cycle.
allowed-tools: Read, Grep, Glob, Bash
---

# Debug

Systematically debug the problem described in `$ARGUMENTS`.
Follow the reproduce → isolate → fix → verify cycle. Do not guess.

## Step 1: Understand the problem
Parse `$ARGUMENTS` for:
- What is the observed behavior?
- What is the expected behavior?
- Is there an error message or stack trace?
- When did this start? After what change?

If critical information is missing, ask for it before proceeding.

## Step 2: Reproduce
Establish a reliable way to reproduce the issue before touching any code.
```bash
# Run relevant tests
# Check logs
# Inspect current state
```
If you cannot reproduce it, say so explicitly — do not guess at a fix.

## Step 3: Isolate
Narrow down the root cause:
- Read the full stack trace if available — start from the bottom
- Find the exact line where behavior diverges from expectation
- Check recent changes in the affected area: `git log --oneline -10 -- <file>`
- Check for similar patterns elsewhere in the codebase that work correctly
- Form a hypothesis: "I believe the issue is X because Y"

For database/query issues (common in this stack):
- Check if the query has correct org scoping
- Check if RLS policies are applied
- Check for N+1 patterns or missing joins
- Log the raw SQL if possible

## Step 4: Fix
Make the minimal change that fixes the root cause.
- Do not fix symptoms — fix the cause
- Do not refactor unrelated code while fixing
- Add a comment if the fix is non-obvious

## Step 5: Verify
Confirm the fix actually works:
```bash
# Run the tests that cover this area
# Re-run the reproduction case
# Check for regressions in related tests
```

## Step 6: Output
Summarize:
- **Root cause**: what was actually wrong
- **Fix**: what was changed and why
- **Verification**: how it was confirmed
- **Follow-up**: anything else that should be addressed (tech debt, missing tests, related risk areas)
