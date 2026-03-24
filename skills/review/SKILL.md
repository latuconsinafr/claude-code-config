---
name: review
description: Use before committing or opening a pull request — reviews staged changes as a principal engineer for correctness, edge cases, and logic flaws. Always invoke this before creating a PR.
allowed-tools: Read, Grep, Glob, Bash
---

# Code Review

Review the current changes as a principal engineer. Do not modify any files during this review.

## Step 1: Get the diff

```bash
git diff --staged
```
If nothing staged:
```bash
git diff HEAD
```
If the diff is empty → tell the user and stop.

## Step 2: Read full context for each changed file

Do not review just the diff lines. For each changed file, read the complete file to understand:
- What the changed function/class does in context
- What callers and dependents exist
- What the surrounding error handling pattern is

## Step 3: Review checklist

Work through each category. Only report findings that apply — skip empty categories.

### Correctness
- Does the logic do what it claims to do?
- Are there off-by-one errors, null/undefined cases, or type mismatches?
- Are all code paths handled — including error paths?
- Are async operations properly awaited? Are race conditions possible?
- Are return values always used or explicitly discarded?
- Does error handling match the pattern used elsewhere in the codebase?

### Edge cases
- What happens with empty input, zero, null, undefined?
- What happens at the boundaries — first item, last item, max value?
- What happens under concurrent requests or retries?
- What happens if an external call fails mid-operation?

### Security
- Are there hardcoded secrets, tokens, or credentials?
- Is user input validated before use? Could it enable SQL/command/path injection?
- Are authentication and authorization checks present and correct?
- Could sensitive data (PII, tokens, passwords) leak into logs or error messages?
- Are there insecure direct object references (accessing records by raw ID without ownership check)?

### Performance
- Are there N+1 query patterns (queries inside loops)?
- Is there synchronous/blocking I/O in a hot path?
- Are there unbounded loops or operations over external data with no limit?
- Could any operation degrade significantly under load?

### Test coverage
- Are there existing tests for the changed behavior?
- Do the changed tests actually cover the new/modified code paths?
- If no tests cover this change, flag it explicitly.

### Code hygiene
- Are there `console.log`, `debugger`, or print statements left in?
- Are there `TODO`/`FIXME`/`HACK` comments introduced by this diff?
- Are there commented-out code blocks that should be deleted?

## Step 4: Output format

Structure the review as:

**🔴 Must fix** — correctness issues, security vulnerabilities, edge cases that will cause bugs
**🟡 Should fix** — logic concerns, missing cases, performance issues, unclear behavior
**🟢 Suggestions** — improvements, not blockers
**✅ Looks good** — solid areas worth calling out explicitly

For each finding: `<file>:<line> — <issue> → <suggested fix>`

End with a verdict line that includes a severity summary:
- `✅ APPROVE` — no issues found
- `⚠️ APPROVE WITH SUGGESTIONS` — only green/yellow findings
- `❌ REQUEST CHANGES — <N> critical, <N> should-fix, <N> suggestions`

If REQUEST CHANGES: list the must-fix items again at the bottom for easy reference.
