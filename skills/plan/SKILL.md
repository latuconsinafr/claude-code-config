---
name: plan
description: Use before writing any code for a new feature, task, or significant change — produces a structured implementation plan with affected files, ordered steps, risks, and open questions. Always invoke this at the start of any non-trivial implementation task and wait for explicit approval before writing code.
allowed-tools: Read, Grep, Glob
---

# Plan

Think through the task before touching any code. No implementation until the plan is confirmed.
Do not write, edit, or delete any files during planning — this skill is read-only.

## Step 1: Understand the task

Read `$ARGUMENTS` carefully.
If the task is ambiguous or underspecified, ask **one clarifying question** before proceeding.

## Step 2: Create a branch

Before any implementation can begin, there must be a branch. Note the branch name to include in the plan:
```
Branch: <type>/<ticket>-<short-description>
e.g. feat/SOC-123-add-refresh-tokens
     fix/GH-42-null-scanner-result
     chore/upgrade-knex-v3
```
Include this in the plan output — the implementer should create this branch before starting Step 1 of the implementation.

## Step 3: Explore the codebase

Use subagents to explore relevant parts without consuming main context:
- Find existing related code (similar patterns, affected modules)
- Identify which files will need to change
- Find tests that cover the affected area
- Check for existing abstractions to reuse

**Divergence check:** If exploration reveals that the codebase is significantly different from what the task description assumes (missing dependencies, conflicting architecture, the feature already partially exists), surface this before writing the plan — do not silently adjust the plan around a mismatch.

## Step 4: Produce the plan

### 🎯 Goal
One sentence — what does this accomplish and why?

### 🌿 Branch
`<type>/<ticket>-<short-description>` — create this before starting

### 📋 Affected files
List files that will be created, modified, or deleted. Note which are the highest-risk changes.

### 🔢 Implementation steps
Ordered steps, each small enough to be a single commit.
For each step: what changes, why in that order, and which steps unblock others.

Ordering principle: highest-risk steps (schema changes, interface changes, external dependencies) first — fail fast if something is blocked.

### ⚠️ Risks & edge cases
- What could go wrong?
- What edge cases need special handling?
- Any migration or schema changes needed?
- Any breaking changes for existing consumers?
- Any external dependencies or blocked work?

### 🧪 Verification
How will we know this is correct?
- What tests need to be written or updated?
- What manual checks are needed?
- What does "done" look like — specific, observable criteria?

### ❓ Open questions
Anything that needs a decision before or during implementation.
If any open question is a blocker, say so explicitly.

## Step 5: Confirm before proceeding

Present the plan and ask:
"Does this plan look right? Should I proceed with implementation, adjust anything, or do you have questions?"

Do not write any code until the plan is explicitly approved.
