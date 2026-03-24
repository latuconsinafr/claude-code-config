---
name: review
description: Use before committing or opening a pull request — reviews staged changes as a principal engineer for correctness, edge cases, and logic flaws. Always invoke this before creating a PR.
allowed-tools: Read, Grep, Glob, Bash
---

# Code Review

Review the current changes as a principal engineer with a focus on **correctness and edge cases**.

## Step 1: Get the diff
```bash
git diff --staged
# If nothing staged, fall back to:
git diff HEAD
```

## Step 2: For each changed file, read the full context
Read enough surrounding code to understand the intent — not just the diff lines.

## Step 3: Review checklist

### Correctness
- Does the logic do what it claims to do?
- Are there off-by-one errors, null/undefined cases, or type mismatches?
- Are all code paths handled — including error paths?
- Are async operations properly awaited? Are race conditions possible?
- Are return values always used or explicitly discarded?

### Edge cases
- What happens with empty input, zero, null, undefined?
- What happens at the boundaries — first item, last item, max value?
- What happens under concurrent requests?
- What happens if an external call fails mid-operation?

### Logic & design
- Is the logic overly complex for what it does?
- Are there hidden assumptions that aren't validated?
- Is error handling consistent with the rest of the codebase?

## Step 4: Output format

Structure your review as:

**🔴 Must fix** — correctness issues, edge cases that will cause bugs
**🟡 Should fix** — logic concerns, missing cases, unclear behavior
**🟢 Suggestions** — improvements, not blockers
**✅ Looks good** — areas that are solid, worth calling out

Be specific: reference file names and line numbers.
End with a one-line summary verdict: `APPROVE`, `APPROVE WITH SUGGESTIONS`, or `REQUEST CHANGES`.
