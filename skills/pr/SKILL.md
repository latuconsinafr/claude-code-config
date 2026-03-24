---
name: pr
description: Use when you are about to open a GitHub pull request — generates a semver-prefixed title ([PATCH/MINOR/MAJOR] TICKET: description) and structured body from commits. Always invoke this instead of running gh pr create directly.
allowed-tools: Bash, Read, Grep
---

# Create Pull Request

Generate a PR title and description, then open it on GitHub.

**Title format:** `[PATCH|MINOR|MAJOR] <TICKET>: <Concise Description>`

## Step 0: Precondition checks

```bash
git status --short
git diff --check
```

- If there are merge conflicts (`git diff --check` exits non-zero or `<<<<<<` markers exist) → stop: "Resolve merge conflicts before opening a PR."
- If the branch has no commits ahead of the base → stop: "Nothing to PR — no commits ahead of base branch."
- Check CI status if available: `gh run list --branch $(git rev-parse --abbrev-ref HEAD) --limit 1` — if the latest run failed, warn: "Latest CI run failed on this branch. Open PR anyway? (yes / fix first)"

## Step 1: Detect base branch dynamically

```bash
git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'
```
Fallback:
```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```
If neither works, default to `main` and note the assumption.

Use the detected base branch for all diff/log commands below.

## Step 2: Parse arguments

`$ARGUMENTS` can be any combination of:
- Empty → auto-detect everything, use fallback template
- Semver level → `PATCH`, `MINOR`, or `MAJOR`
- Ticket → `GH-45`, `SOC-123`, `VUL-456`, etc.
- `@file` reference → `@.github/pull_request_template.md` (content already in context)

Parse `$ARGUMENTS` by scanning for:
- `PATCH|MINOR|MAJOR` → semver level
- `GH-\d+` → GitHub issue, transform to `#<number>` for PR title
- `[A-Z]+-\d+` (not GH) → Jira-style ticket, use as-is
- `@...` → custom template already in context, use it directly

If no template in arguments → read fallback from [template.md](template.md).

## Step 3: Gather context

```bash
BASE=$(detected base branch from Step 1)
git rev-parse --abbrev-ref HEAD
git log $BASE...HEAD --oneline
git diff $BASE...HEAD --stat
git diff $BASE...HEAD
```

## Step 4: Detect ticket and format correctly

**A. If ticket was in `$ARGUMENTS`** — already parsed in Step 2, use it directly.

**B. Otherwise extract from branch name:**
```bash
git rev-parse --abbrev-ref HEAD
```
- `GH-\d+` or bare `\d+` in branch → GitHub issue → format as `#<number>`
- `[A-Z]+-\d+` (non-GH) → Jira ticket → use as-is

**C. If still no ticket found** → ask: "What's the ticket? (e.g. SOC-123 or GH-45, or 'none')"

## Step 5: Determine semver level

If not in `$ARGUMENTS`, infer from the diff:

**MAJOR** — breaking changes:
- Removed or renamed public API endpoints
- Incompatible request/response contract change
- Dropped something consumers depend on

**MINOR** — new functionality, backward compatible:
- New endpoint, new field, new feature, new optional parameter

**PATCH** — fix or internal change, no API impact:
- Bug fix, refactor, perf improvement, test, chore, docs

**Ambiguity check:** If the diff contains both new features (`feat`) and bug fixes (`fix`), ask: "This PR contains both new functionality and bug fixes — should the semver level be MINOR (for the feature), or do you want to split into separate PRs?" Do not silently pick one.

## Step 6: Generate PR title

```
[PATCH] SOC-123: fix token expiry not refreshing on concurrent requests
[MINOR] #45: add pagination to vulnerability list endpoint
[MAJOR] VUL-789: remove deprecated v1 scan API
```

Rules:
- Max 72 characters after the prefix
- Imperative mood, lowercase after the ticket
- Specific enough to understand without reading the body

## Step 7: Fill in the template

Use the template (from `@file` argument or fallback `template.md`) and fill each section based on the diff and commits.

**Critical:** Do not leave placeholder comments in the output. After filling the template, scan it for common placeholder strings (`<!-- -->`, `[TODO]`, `Add description here`, `_replace this_`, `N/A if not applicable`) and either replace them with real content or remove the section entirely. A PR with placeholder text is worse than a PR with no template.

## Step 8: Show and confirm

Display full title and description, then ask:
"Open this PR on GitHub? (yes / draft / edit / cancel)"

- **yes** → `gh pr create --title "<title>" --body "<description>"`
- **draft** → `gh pr create --title "<title>" --body "<description>" --draft`
- **edit** → let user modify, then create
- **cancel** → display content for manual use
