---
name: pr
description: Generate a GitHub pull request with semver-prefixed title and structured description. Format is [PATCH/MINOR/MAJOR] TICKET: description. Supports custom PR templates via @ file reference.
allowed-tools: Bash, Read, Grep
---

# Create Pull Request

Generate a PR title and description, then open it on GitHub as a draft.

**Title format:** `[PATCH|MINOR|MAJOR] <TICKET>: <Concise Description>`

## Step 1: Parse arguments

`$ARGUMENTS` can be any combination of:
- Empty → auto-detect everything, use fallback template
- Semver level → `PATCH`, `MINOR`, or `MAJOR`
- Ticket → `GH-45`, `SOC-123`, `VUL-456`, etc.
- `@file` reference → `@.github/pull_request_template.md` (content already in context)

Examples:
```
/pr
/pr PATCH
/pr SOC-123
/pr GH-45
/pr PATCH SOC-123
/pr PATCH @.github/pull_request_template.md
/pr PATCH SOC-123 @.github/pull_request_template.md
```

Parse `$ARGUMENTS` by scanning for:
- `PATCH|MINOR|MAJOR` → semver level
- `GH-\d+` → GitHub issue, transform to `#<number>` for PR title
- `[A-Z]+-\d+` (not GH) → Jira-style ticket, use as-is (e.g. `SOC-123`, `VUL-456`)
- `@...` → custom template already in context, use it directly

If no template in arguments → read fallback from [template.md](template.md).

## Step 2: Gather context
```bash
git rev-parse --abbrev-ref HEAD
git log main...HEAD --oneline
git diff main...HEAD --stat
git diff main...HEAD
```

## Step 3: Detect ticket and format correctly

**A. If ticket was in `$ARGUMENTS`** — already parsed in Step 1, use it directly.

**B. Otherwise extract from branch name:**
```bash
git rev-parse --abbrev-ref HEAD
```
- `GH-\d+` or bare `\d+` in branch → GitHub issue → format as `#<number>`
- `[A-Z]+-\d+` (non-GH) → Jira ticket → use as-is

**C. If still no ticket found** → ask: "What's the ticket? (e.g. SOC-123 or GH-45, or 'none')"

**Formatting rule:**
- `GH-45` → `#45` (GitHub tracks via `#number` in UI)
- `SOC-123`, `VUL-456`, any other pattern → use as-is

## Step 4: Determine semver level

If not in `$ARGUMENTS`, infer from the diff:

**MAJOR** — breaking changes:
- Removed or renamed public API endpoints
- Incompatible request/response contract change
- Dropped something consumers depend on

**MINOR** — new functionality, backward compatible:
- New endpoint, new field, new feature, new optional parameter

**PATCH** — fix or internal change, no API impact:
- Bug fix, refactor, perf improvement, test, chore, docs

When uncertain between MINOR and PATCH → ask the user.

## Step 5: Generate PR title

```
[PATCH] SOC-123: fix token expiry not refreshing on concurrent requests
[MINOR] #45: add pagination to vulnerability list endpoint
[MAJOR] VUL-789: remove deprecated v1 scan API
```

Rules:
- Max 72 characters after the prefix
- Imperative mood, lowercase after the ticket
- Specific enough to understand without reading the body

## Step 6: Fill in the template

Use the template (from `@file` argument or fallback `template.md`) and fill each section based on the diff and commits. Do not leave placeholder comments — replace them with real content or remove the section if not applicable.

## Step 7: Show and confirm
Display full title and description, then ask:
"Open this PR on GitHub as draft? (yes / edit / cancel)"

- **yes** → `gh pr create --title "<title>" --body "<description>" --draft`
- **edit** → let user modify, then create
- **cancel** → display content for manual use
