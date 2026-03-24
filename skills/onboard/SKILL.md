---
name: onboard
description: Use at the start of a session on an unfamiliar or returning project — reads architecture docs, recent activity, open work, and coding conventions to prime context before starting any task. Invoke this before /plan or /issue when you haven't worked on the project recently.
allowed-tools: Read, Grep, Glob, Bash
---

# Project Onboarding

Prime context about the project before starting work. Do not modify any files.

## Step 1: Identify the project

```bash
pwd
basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)
git remote get-url origin 2>/dev/null
```

## Step 2: Read project documentation

Find and read in priority order:

**Primary docs:**
```bash
find . -maxdepth 2 -name "CLAUDE.md" -o -name "README.md" -o -name "README.rst" \
  -o -name "ARCHITECTURE.md" -o -name "CONTRIBUTING.md" 2>/dev/null | \
  grep -v node_modules | head -10
```

**Architecture / design docs:**
```bash
find . -maxdepth 3 -type d -name "docs" -o -name "doc" -o -name "documentation" \
  2>/dev/null | grep -v node_modules | head -3
```
Read any `architecture.*`, `overview.*`, `design.*`, `adr/` files found.

**Environment setup:**
```bash
find . -maxdepth 2 -name ".env.example" -o -name ".env.sample" \
  -o -name "Makefile" -o -name "justfile" 2>/dev/null | grep -v node_modules
```

## Step 3: Understand the stack

```bash
# Detect language and framework
cat package.json 2>/dev/null | jq '{name, version, main, scripts, dependencies: (.dependencies // {} | keys), devDependencies: (.devDependencies // {} | keys | map(select(test("jest|vitest|eslint|prettier|typescript"))))}'
cat go.mod 2>/dev/null | head -20
cat Cargo.toml 2>/dev/null | head -20
cat pyproject.toml requirements.txt 2>/dev/null | head -20
```

Extract:
- Primary language and runtime version
- Main framework (Express, NestJS, FastAPI, Gin, etc.)
- Database(s) in use
- Test framework
- Key dependencies

## Step 4: Understand the project structure

```bash
# Top-level structure
find . -maxdepth 2 -type d | grep -v "node_modules\|\.git\|dist\|build\|coverage\|\.next" | sort

# Entry points
find . -maxdepth 3 -name "main.*" -o -name "index.*" -o -name "app.*" -o -name "server.*" \
  2>/dev/null | grep -v node_modules | grep -v dist | head -10
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
