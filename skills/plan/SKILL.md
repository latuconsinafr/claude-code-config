---
name: plan
description: Use before writing any code for a new feature, task, or significant change — produces a structured implementation plan with affected files, ordered steps, risks, and open questions. Always invoke this at the start of any non-trivial implementation task and wait for explicit approval before writing code.
allowed-tools: Agent, Read, Grep, Glob, Bash
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

## Step 3: Explore the codebase — spawn the `explorer` agent

Spawn the `explorer` agent to map the relevant codebase area without consuming main context. Pass:
```
Task: <description from Step 1>
Find:
- Existing related code and similar patterns in the codebase
- Files that will likely need to change
- Tests covering the affected area
- Existing abstractions that could be reused or extended
- Any prior attempts at this feature (TODOs, partial implementations, comments)
```

**Divergence check:** If the explorer finds that the codebase is significantly different from what the task assumes (missing dependencies, conflicting architecture, the feature already partially exists), surface this before writing the plan — do not silently adjust the plan around a mismatch.

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

## Step 5: Architect validation (for complex plans)

If the plan involves any of the following, spawn the `architect` agent to validate the design before presenting it to the user:
- Changes to core data models or database schema
- New service boundaries or module interfaces
- Changes to authentication or authorization logic
- Anything that will be difficult or expensive to reverse

Pass the draft plan to the `architect` agent with:
```
Review this implementation plan for design correctness, reversibility, and system implications.
Flag anything that will be costly to change later.
```

Incorporate the architect's blocking concerns into the plan before presenting. Non-blocking concerns can be surfaced as risks.

For straightforward plans (single-file changes, UI tweaks, config updates) — skip this step.

## Step 6: Present the plan and assess E2E test case need

Present the full plan to the user.

Then assess whether E2E test cases are needed, using this decision table:

**Auto-include test cases** (generate without asking) if ALL of these are true:
- Architect validation was triggered in Step 5 (plan is complex enough to warrant it)
- Plan touches 2+ services or has 3+ implementation steps
- Plan involves API endpoint changes OR DB schema changes

If auto-including: append to the plan output:
```
---
**Test Cases:** This plan involves [state the reasons: API changes / DB schema changes / multi-service integration]. I'll generate E2E test case documentation now using the context from this plan.
```
Then immediately invoke `/test-cases` with the plan context already available (no need to re-explore).

---

**Offer test cases** (ask the user) if ANY ONE of these is true, but auto-include criteria are not fully met:
- Plan involves API endpoint changes (new endpoints or changed request/response shape)
- Plan involves DB schema changes or new tables
- Plan involves multi-service integration or queue dispatch
- Plan description mentions testing, QA, validation, or E2E

If offering: append to the plan output:
```
---
**Test Cases:** This plan involves [state the reason]. Should I generate E2E test case documentation now? I already have the codebase context from this plan — it won't require re-exploration. (yes / skip)
```
Wait for the user's response. If "yes", invoke `/test-cases` with existing context.

---

**Skip test cases** if the plan is:
- A single-file change with no API or DB impact
- A config update, copy change, or dependency bump
- A refactor with no behavior change

In these cases, end with:
```
Does this plan look right? Should I proceed with implementation, adjust anything, or do you have questions?
```

Do not write any code until the plan is explicitly approved.
