---
name: simplify
description: Use when a file or module has grown too complex — removes unnecessary abstractions, dead code, and over-engineering without changing behavior. Invoke after implementing a feature when the code feels over-engineered.
allowed-tools: Agent, Read, Grep, Glob, Bash
---

# Simplify

Simplify the code in `$ARGUMENTS` (file or module path).
If no argument — simplify the most recently edited file.

## Guiding principle
> The best code is code that doesn't exist. The second best is code that's obvious.

## Spawn the `refactoring` agent

The `refactoring` agent handles the full simplification workflow: test baseline verification, blast radius checks, identifying complexity sources, proposing and applying changes one at a time, and re-running tests after each step.

Spawn it with the following task:
```
Target: <file or module path from $ARGUMENTS, or most recently edited file>
Goal: simplify — remove unnecessary abstractions, dead code, and over-engineering
      without changing behavior
Constraint: behavior must be identical before and after each change
```

The agent will:
1. Verify the test suite is green before starting
2. Warn if on `main`/`master` branch
3. Check blast radius for every symbol it considers removing
4. Propose changes grouped by risk (safe / needs verification / out of scope)
5. Ask for confirmation before applying
6. Apply and re-run tests after each change, reverting on failure

## After the agent completes

Review the agent's summary:
- All changes made and tests verified
- Any blocked changes (failed tests on attempt) — note these for a separate follow-up
- Deferred items (bugs or features noticed but not touched during refactor)
