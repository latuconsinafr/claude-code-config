---
name: commit
description: Generate a conventional commit message from staged changes. Format is feat(scope): TICKET-123 description. Supports both Jira (SOC-123) and GitHub issues (GH-42). Scope is inferred dynamically from changed files.
allowed-tools: Bash, Read
---

# Generate Commit Message

Generate a conventional commit message for staged changes.

**Target format:** `<type>(<scope>): <TICKET> <description>`

## Step 1: Check for staged changes
```bash
git diff --staged --stat
git diff --staged
```
If nothing staged → tell the user: "No staged changes. Run `git add` first."

## Step 2: Detect ticket number

Check in this order:

**A. From `$ARGUMENTS`** — if the user passed a ticket (e.g. `/commit SOC-123` or `/commit GH-42`), use it.

**B. From branch name:**
```bash
git rev-parse --abbrev-ref HEAD
```
Extract ticket using these patterns:
- Jira: `SOC-\d+` or any `[A-Z]+-\d+` pattern
- GitHub issue: `GH-\d+` or bare number like `feature/42-...`
- If bare number found, ask: "Is this SOC-42 or GH-42?"

**C. If no ticket found:**
Ask: "What's the ticket number? (e.g. SOC-123 or GH-42, or type 'none' to skip)"

## Step 3: Determine commit type
Based on the diff:
- `feat` — new feature or behavior
- `fix` — bug fix
- `refactor` — restructure without behavior change
- `test` — adding or updating tests
- `chore` — deps, config, tooling, build
- `docs` — documentation only
- `perf` — performance improvement
- `ci` — CI/CD pipeline changes

## Step 4: Infer scope dynamically

Look at the staged file paths from `git diff --staged --stat` and infer the most meaningful scope:

- If all changed files share a common directory → use that directory name
  - `src/auth/...` → `auth`
  - `services/scanner/...` → `scanner`
  - `packages/api/...` → `api`
- If files span multiple directories → use the closest common parent
  - `src/auth/guard.ts` + `src/auth/token.ts` → `auth`
  - `src/auth/...` + `src/scan/...` → no single scope, omit or use the primary one
- If files are config/root level → use `config` or omit scope entirely
- If it's a single file change → use the file's parent directory name

The scope should reflect **what part of the system changed**, not the file type.
Never use generic scopes like `src`, `lib`, `utils` — go one level deeper.

## Step 5: Write the commit message

**Subject line:**
```
<type>(<scope>): <TICKET> <description>
```
- Max 72 characters total
- Description: lowercase, imperative mood ("fix" not "fixes" or "fixed")
- Ticket immediately before description, no punctuation between them
- If no ticket: omit it — `feat(auth): add refresh token rotation`
- If no clear scope: omit it — `fix: SOC-123 handle null response`

Examples:
```
feat(auth): SOC-123 add refresh token rotation
fix(scanner): GH-42 handle null result from scanner API
chore(deps): upgrade knex to v3
refactor: SOC-456 extract org context into middleware
```

**Body (optional, include for non-trivial changes):**
```

<blank line>
<why this change was needed — the problem solved, not a restatement of the diff>
```

## Step 6: Show and confirm
Display the full commit message, then ask:
"Run `git commit` with this message? (yes / edit / cancel)"

- **yes** → run `git commit -m "<message>"`
- **edit** → show the message for the user to modify, then commit
- **cancel** → just display the message, do nothing
