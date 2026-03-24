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

## Step 2: Spawn the `reviewer` agent

Spawn the `reviewer` agent to perform the review in isolation. Pass:
- The full diff (output of Step 1)
- The list of changed files

The `reviewer` agent will read full file context for each changed file (not just diff lines), work through the complete review checklist, and return structured findings.

## Step 3: Present the verdict

Take the `reviewer` agent's output and present it directly. Do not summarize or filter findings.

If the verdict is `❌ REQUEST CHANGES`: list the must-fix items again at the bottom for easy reference before proceeding.
