---
name: onboard
description: Use at the start of a session on an unfamiliar or returning project — reads architecture docs, recent activity, open work, and coding conventions to prime context before starting any task. Invoke this before /plan or /issue when you haven't worked on the project recently.
allowed-tools: Agent, Read, Grep, Glob, Bash
---

# Project Onboarding

Prime context about the project before starting work. Do not modify any files.

## Step 1: Identify the project

```bash
pwd
basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)
git remote get-url origin 2>/dev/null
```

## Step 2: Map the project — spawn the `explorer` agent

Spawn the `explorer` agent to investigate the project's documentation and structure. Pass:
```
Project directory: <pwd from Step 1>
Investigate and return:

1. Documentation: read CLAUDE.md, README.md/rst, ARCHITECTURE.md, CONTRIBUTING.md
   (maxdepth 2). Also read any architecture.*, overview.*, design.*, or adr/ files
   found in docs/ subdirectories.

2. Environment setup: find .env.example, .env.sample, Makefile, justfile (maxdepth 2).
   Note any required env vars or setup steps.

3. Stack: detect primary language and runtime from package.json / go.mod / Cargo.toml /
   pyproject.toml. Extract: language, framework, database(s), test runner, key dependencies.

4. Project structure: list top-level directories (maxdepth 2), excluding node_modules,
   .git, dist, build, coverage, .next. Find entry points: main.*, index.*, app.*, server.*

Return a structured summary of all findings.
```

## Step 5: Recent activity

```bash
# What's been worked on recently
git log --oneline --since="2 weeks ago" 2>/dev/null | head -20

# Open branches (active work)
git branch -r 2>/dev/null | grep -v HEAD | head -10

# Recent files changed
git diff --name-only HEAD~10 HEAD 2>/dev/null | sort -u | head -20
```

## Step 6: Open work

```bash
# Open PRs
gh pr list --limit 10 2>/dev/null

# Open issues assigned to you or unassigned
gh issue list --limit 10 --assignee "@me" 2>/dev/null
gh issue list --limit 5 --state open 2>/dev/null
```

If `gh` is not available, skip silently.

## Step 7: Coding conventions

Scan for project-specific conventions:

```bash
# Linting / formatting config
find . -maxdepth 2 -name ".eslintrc*" -o -name "eslint.config.*" \
  -o -name ".prettierrc*" -o -name "biome.json" \
  -o -name ".golangci*" -o -name "pyproject.toml" \
  -o -name ".rubocop*" 2>/dev/null | grep -v node_modules | head -5

# Git conventions
cat .gitmessage 2>/dev/null
find . -maxdepth 3 -path "*/.git/hooks/commit-msg" 2>/dev/null | xargs cat 2>/dev/null | head -30
```

Note any enforced commit message format, branch naming patterns, or PR conventions.

## Step 8: Produce the context summary

Structure output as:

### 🏗️ Project
**Name:** `<project name>`
**Repo:** `<remote URL>`
**Stack:** `<language> + <framework> + <database>`
**Test runner:** `<jest/pytest/go test/etc>`

### 📁 Structure
Brief description of the top-level directories and what lives where.

### 🔄 Recent activity
What has been actively worked on in the last 2 weeks. What areas are "hot."

### 🌿 Active branches
Open branches and what they're working on (inferred from branch names + recent commits).

### 📋 Open work
Open PRs and issues. What's in flight.

### 📐 Conventions
- Commit format: `<detected format>`
- Branch naming: `<detected pattern>`
- Code style: `<linter/formatter in use>`
- Any other project-specific rules found in CLAUDE.md or CONTRIBUTING.md

### ⚠️ Things to know
Anything from the docs that's non-obvious — gotchas, known issues, things to be careful about.

### ✅ Ready
"Context loaded. You can now use /issue, /plan, or ask questions about the codebase."
