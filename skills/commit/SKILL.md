---
name: commit
description: Use when you are about to create a git commit — generates a conventional commit message with type(scope): TICKET description format. Auto-detects ticket from branch name or arguments. Always use this instead of running git commit directly.
allowed-tools: Bash, Read
---

# Generate Commit Message

Generate a conventional commit message for staged changes.

**Target format:** `<type>(<scope>): <TICKET> <description>`

## Step 0: Precondition checks

```bash
git status --short
git diff --staged --stat
```

- If this is a merge commit (`git log --merges -1 HEAD` returns the current HEAD) → skip conventional format, use `merge: <branch> into <branch>` and exit.
- If nothing is staged → offer: "Nothing staged. Should I run `git add -p` to interactively stage changes, or `git add .` to stage everything?"
- If `git diff --staged` and `git diff` differ significantly (i.e., there are unstaged changes alongside staged changes) → warn: "You have unstaged changes alongside staged ones. The commit message will only reflect the staged portion — is that intended?"

## Step 1: Dirty-diff check

Scan `git diff --staged` for:
- `console.log`, `console.error`, `console.warn`, `debugger` statements
- Hardcoded secrets patterns: API keys, tokens, passwords in strings (`key=`, `secret=`, `password=`, `Bearer `, `sk-`, etc.)
- `TODO`, `FIXME`, `HACK`, `XXX` comments introduced by this diff (not pre-existing)
- Commented-out code blocks

If any found → list them and ask: "These were found in the staged diff — intentional or should they be cleaned up first?"

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

Based on the diff — if the diff contains changes that span multiple types (e.g., both a new feature and a bug fix), **ask** rather than picking one: "This diff looks like it contains both a feature and a fix — should this be split into two commits, or which type best represents the primary intent?"

Types:
- `feat` — new feature or behavior
- `fix` — bug fix
- `security` — security fix or hardening (vulnerability patch, auth fix, input sanitization)
- `refactor` — restructure without behavior change
- `test` — adding or updating tests
- `chore` — deps, config, tooling, build
- `docs` — documentation only
- `perf` — performance improvement
- `ci` — CI/CD pipeline changes
- `revert` — revert a previous commit
- `build` — build system or external dependency changes

## Step 4: Detect breaking changes

Scan the diff for:
- Removed or renamed exported functions, classes, or types
- Changed function signatures (parameter removed, type changed)
- Removed API endpoints or changed response shapes
- Renamed environment variables or config keys

If any found → mark as breaking change. This affects both the subject line (`!`) and requires a `BREAKING CHANGE:` footer. Note this for Step 6.

## Step 5: Infer scope dynamically

Look at the staged file paths from `git diff --staged --stat` and infer the most meaningful scope:

- If all changed files share a common directory → use that directory name
  - `src/auth/...` → `auth`
  - `services/scanner/...` → `scanner`
- If files span multiple directories → use the closest common parent
- If files are config/root level → use `config` or omit scope entirely
- If it's a single file change → use the file's parent directory name

Never use generic scopes like `src`, `lib`, `utils` — go one level deeper.

## Step 6: Write the commit message

**Subject line format:**
```
<type>(<scope>): <TICKET> <description>       ← normal change
<type>(<scope>)!: <TICKET> <description>      ← breaking change with scope
<type>!: <TICKET> <description>               ← breaking change, no scope
```

Rules:
- The `!` goes between the scope (or type) and the `:` — signals breaking change at a glance in git log
- Max 72 characters total
- Description: lowercase, imperative mood ("fix" not "fixes" or "fixed")
- Ticket immediately before description, no punctuation between them
- If no ticket: omit it — `feat(auth): add refresh token rotation`
- If no clear scope: omit it — `fix: GH-123 handle null response`

**Body (include for non-trivial changes):**
```

<blank line>
<why this change was needed — the problem it solves, not a restatement of the diff>
```

**Breaking change footer (required when `!` is used — describes what broke and migration path):**
```

BREAKING CHANGE: <what broke and what callers need to do instead>
```

Examples:
```
feat(auth): GH-123 add refresh token rotation

Previously tokens expired with no renewal path, causing silent session
drops after 1 hour.

feat(api): GH-42 add pagination to scan results endpoint

fix(scanner): GH-99 handle null result from external scanner API

security(auth): GH-201 enforce rate limiting on login endpoint

chore(deps): upgrade knex to v3

refactor(auth)!: GH-456 rename UserContext to OrgContext

BREAKING CHANGE: UserContext is now OrgContext in all imports. Update
all `import { UserContext }` to `import { OrgContext }`.

feat!: GH-789 replace REST with GraphQL API

BREAKING CHANGE: All REST endpoints removed. Migrate to /graphql.
See migration guide in docs/graphql-migration.md.
```

## Step 7: Show and confirm
Display the full commit message, then ask:
"Run `git commit` with this message? (yes / edit / cancel)"

- **yes** → run `git commit -m "<message>"` (use `-m $'...'` for multi-line with body/footer)
- **edit** → display the raw message text for the user to modify inline, then commit
- **cancel** → just display the message, do nothing
