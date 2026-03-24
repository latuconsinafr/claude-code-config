---
name: simplify
description: Use when a file or module has grown too complex — removes unnecessary abstractions, dead code, and over-engineering without changing behavior. Invoke after implementing a feature when the code feels over-engineered.
allowed-tools: Read, Grep, Glob, Bash
---

# Simplify

Simplify the code in `$ARGUMENTS` (file or module path).
If no argument — simplify the most recently edited file.

## Guiding principle
> The best code is code that doesn't exist. The second best is code that's obvious.

## Step 0: Safety baseline

Before touching anything:

**a. Verify tests pass:**
```bash
# Auto-detect test runner from package.json / go.mod / Cargo.toml / etc.
# Run the test suite for the target file/module
```
If tests fail before you start → stop: "Tests are already failing. Fix the failures before simplifying, otherwise you can't verify behavior is preserved."

**b. Confirm you're on a branch:**
```bash
git rev-parse --abbrev-ref HEAD
```
If on `main` or `master` → warn: "You're on the main branch. Simplification changes should be made on a feature branch. Continue anyway? (yes / create branch)"

## Step 1: Read the full file

Understand what it does before suggesting any changes. Do not skim.

## Step 2: Check blast radius before proposing removals

For any function, class, type, or abstraction you're considering removing or merging:
```bash
grep -r "<name>" --include="*.<ext>" . | grep -v "^Binary" | wc -l
```
If used in more than 3 files → note the blast radius in your proposal. Do not silently propose cross-file removals — scope those separately.

For anything that looks dead (unused exports, unreferenced code):
```bash
git log --oneline -5 -- <file>
```
If recently added (within last 10 commits) → check the commit message before marking it dead. It may be in-progress work or intentionally staged.

## Step 3: Identify complexity sources

### Unnecessary abstractions
- Classes that wrap a single function
- Interfaces with only one implementation and no plans for more
- Generic types that add no type safety benefit
- Factories or registries for things that don't need dynamic registration

### Dead code
- Unused functions, variables, imports, types
- Commented-out code blocks
- Feature flags that are always true or always false
- Exports that are never imported anywhere (verified by grep)

### Over-engineering
- Flag parameters that switch behavior (split into two functions)
- Functions doing more than one thing
- Deeply nested conditionals that could be early-returned
- Premature optimization without evidence of a bottleneck

### Readability issues
- Variable names that don't communicate intent
- Long functions that should be extracted
- Inconsistent patterns vs. the rest of the codebase

## Step 4: Propose changes

For each identified issue:
- Show the current code
- Show the simplified version
- Explain what was removed/changed and why it's better
- Note blast radius if cross-file

Group proposals by risk:
- **Safe (single-file, covered by tests):** can apply together
- **Needs verification (cross-file or test coverage unclear):** apply one at a time
- **Out of scope (requires broader refactor):** note but do not apply

## Step 5: Confirm before applying

List all proposed changes grouped by risk and ask:
"Should I apply all of these, or would you like to review each group?"

## Step 6: Apply and verify

After applying each change or group:
```bash
# Run the tests again
```
If any test fails → revert that specific change, note it as blocked, and continue with the remaining safe changes.

## Rules
- Never change behavior — only structure
- Never remove something you can't verify is unused (use grep, not assumption)
- If a simplification requires changes across more than 3 files, scope it separately
