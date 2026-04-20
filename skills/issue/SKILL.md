---
name: issue
description: Use when starting work on a GitHub or Jira issue — reads the issue, explores affected code, and produces a ready-to-execute implementation plan. Invoke this at the start of any ticket-driven task instead of jumping straight to /plan.
allowed-tools: Agent, Bash, Read, Grep, Glob
---

# Issue → Plan

Turn a ticket into an implementation plan without manual context switching.

## Step 1: Parse arguments

`$ARGUMENTS` can be:
- GitHub issue number: `45`, `GH-45`, `#45`
- Jira ticket: `SOC-123`, `PROJ-456`
- URL: `https://github.com/owner/repo/issues/45`
- Empty → ask: "What's the issue number or ticket?"

Normalize to a clean identifier for fetching.

## Step 2: Fetch the issue

**GitHub (try first):**
```bash
gh issue view <number> --json title,body,labels,assignees,milestone,comments
```

If that succeeds → extract:
- `title` — the issue title
- `body` — full description, acceptance criteria, reproduction steps
- `labels` — bug / feature / chore / security etc.
- `comments` — any clarifying discussion (especially last 3–5 comments)

If `gh` fails (not a GitHub repo, not authenticated, or it's a Jira ticket):
→ Ask: "I couldn't fetch the issue automatically. Please paste the issue title and description."
→ Continue with the pasted content.

**Jira:**
```bash
# If JIRA_API_TOKEN and JIRA_BASE_URL are set:
curl -s -H "Authorization: Bearer $JIRA_API_TOKEN" \
  "$JIRA_BASE_URL/rest/api/3/issue/<ticket>" | jq '{
    title: .fields.summary,
    body: .fields.description,
    labels: [.fields.labels[]],
    status: .fields.status.name
  }'
```
If env vars not set → fall back to paste.

## Step 3: Understand the issue

From the fetched content, extract:
- **What problem does this solve?** (not just what to build)
- **Acceptance criteria** — explicit or implied from the description
- **Issue type** — infer from labels or description: bug fix, new feature, refactor, chore, security
- **Constraints or decisions** already made in comments

If critical information is missing (no acceptance criteria, ambiguous scope) → ask one clarifying question before exploring the codebase.

## Step 4: Explore the codebase

Use subagents to find relevant context:
- Files most likely affected based on the issue description
- Existing code related to the feature area
- Tests covering the affected area
- Similar patterns already in the codebase to reuse

**Divergence check:** if exploration reveals something that contradicts the issue (feature already exists, dependency missing, conflicting architecture) → surface it before writing the plan.

## Step 5: Produce the implementation plan

### 🎫 Issue
`<type> #<number>: <title>` (or `<TICKET>: <title>` for Jira)

### 🎯 Goal
One sentence — what problem does this solve and for whom?

### 🌿 Branch
`<type>/<ticket>-<slug>`
e.g. `feat/GH-45-add-product-search`, `fix/SOC-123-null-token-handler`

### 📋 Affected files
Files to create, modify, or delete. Flag highest-risk changes.

### 🔢 Implementation steps
Ordered steps, each scoped to a single commit.
Highest-risk steps (schema, interface, external dependencies) first.
Note which steps unblock others.

### 🧪 Acceptance criteria
Map directly from the issue — each criterion must be verifiable.
Add any implied criteria the issue didn't state explicitly.

### ⚠️ Risks & edge cases
- What could go wrong?
- Any schema or migration changes needed?
- Any breaking changes for consumers?
- Any external blockers?

### ❓ Open questions
Unresolved questions that need a decision before or during implementation.

## Step 6: Confirm before proceeding

Present the plan and ask:
"Does this match the intent of the issue? Should I proceed, adjust, or do you have questions?"

Do not write any code until the plan is explicitly approved.
