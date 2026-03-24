---
name: plan
description: Use before writing any code for a new feature, task, or significant change — produces a structured implementation plan with affected files, ordered steps, risks, and open questions. Always invoke this at the start of any non-trivial implementation task and wait for explicit approval before writing code.
allowed-tools: Read, Grep, Glob, Bash
---

# Plan

Think through the task before touching any code. No implementation until the plan is confirmed.

## Step 1: Understand the task
Read `$ARGUMENTS` carefully.
If the task is ambiguous, ask **one clarifying question** before proceeding.

## Step 2: Explore the codebase
Use subagents to explore relevant parts without consuming main context:
- Find existing related code (similar patterns, affected modules)
- Identify which files will need to change
- Find tests that cover the affected area
- Check for any existing abstractions to reuse

```bash
# Get a sense of structure
git ls-files | head -50
```

## Step 3: Produce the plan

Structure:

### 🎯 Goal
One sentence — what does this accomplish?

### 📋 Affected files
List files that will be created, modified, or deleted.

### 🔢 Implementation steps
Ordered steps, each small enough to be a single commit.
For each step: what changes, and why in that order.

### ⚠️ Risks & edge cases
- What could go wrong?
- What edge cases need special handling?
- Any migration or schema changes needed?
- Any breaking changes for existing consumers?

### 🧪 Verification
How will we know this is correct?
- What tests need to be written or updated?
- What manual checks are needed?
- What does "done" look like?

### ❓ Open questions
Anything that needs a decision before or during implementation.

## Step 4: Confirm before proceeding
Present the plan and ask:
"Does this plan look right? Should I proceed with implementation, adjust anything, or do you have questions?"

Do not write any code until the plan is explicitly approved.
