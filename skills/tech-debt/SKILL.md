---
name: tech-debt
description: Use when you want to surface accumulated technical debt — scans for TODOs, deprecated APIs, dead code, and code quality issues. Produces a prioritized list with age and estimated effort. Run periodically or before planning a refactor sprint.
allowed-tools: Read, Grep, Glob, Bash
---

# Tech Debt Scan

Surface accumulated technical debt across the codebase. Do not modify any files — this is a read-only audit.

## Step 1: Scope

If `$ARGUMENTS` is provided → scan only that directory or file.
If empty → scan the entire codebase, excluding:
- `node_modules/`, `vendor/`, `.git/`, `dist/`, `build/`, `coverage/`
- Generated files (`*.generated.ts`, `*.pb.go`, etc.)
- Lockfiles

## Step 2: TODO / FIXME / HACK markers

```bash
grep -rn "TODO\|FIXME\|HACK\|XXX\|NOSONAR\|@deprecated\|@todo" \
  --include="*.ts" --include="*.js" --include="*.py" --include="*.go" \
  --include="*.rs" --include="*.rb" --include="*.java" \
  --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.git \
  . 2>/dev/null
```

For each hit, get its age:
```bash
git log --follow -1 --format="%ar|%s" -- <file> 2>/dev/null
```

Markers older than 6 months are higher priority than recent ones.

## Step 3: Deprecated API usage

Detect usage of APIs known to be deprecated in the project's stack:

**Node/JS/TS:**
```bash
# Common deprecated patterns
grep -rn "\.substr(\|new Buffer(\|require('sys')\|process.binding\|fs.exists(" \
  --include="*.ts" --include="*.js" --exclude-dir=node_modules . 2>/dev/null
```

**Check package.json for deprecated packages:**
```bash
npm outdated --json 2>/dev/null | jq 'to_entries[] | select(.value.current != .value.latest)'
```

**Framework-specific deprecations** — read the project's main framework (from `package.json`, `go.mod`, etc.) and check for patterns known to be deprecated in that version.

## Step 4: Dead code candidates

```bash
# Exported but never imported (TypeScript/JS)
grep -rn "^export " --include="*.ts" --include="*.js" \
  --exclude-dir=node_modules . 2>/dev/null | while read -r match; do
  symbol=$(echo "$match" | grep -oE 'export (const|function|class|type|interface|enum) \w+' | awk '{print $NF}')
  file=$(echo "$match" | cut -d: -f1)
  [ -n "$symbol" ] && count=$(grep -r "$symbol" --include="*.ts" --include="*.js" \
    --exclude-dir=node_modules . 2>/dev/null | grep -v "^$file" | wc -l)
  [ "${count:-0}" -eq 0 ] && echo "UNUSED: $symbol in $file"
done
```

Also look for:
- Commented-out code blocks (3+ consecutive commented lines)
- Feature flags that are hardcoded to `true` or `false`
- Environment variables referenced in code but not defined anywhere (overlap with `/env-audit`)

## Step 5: Code quality signals

```bash
# Long files (over 300 lines — often a sign of too many responsibilities)
find . -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" | \
  grep -v node_modules | grep -v vendor | \
  xargs wc -l 2>/dev/null | sort -rn | head -20

# Long functions — files with functions over 50 lines
# (approximate: look for large gaps between function definitions)
```

## Step 6: Produce prioritized report

### 🔴 High priority
- TODOs/FIXMEs older than 6 months
- Deprecated APIs with available replacements
- Security-related HACKs

### 🟡 Medium priority
- TODOs/FIXMEs 1–6 months old
- Dead code with blast radius > 0 (used in ≥1 file but possibly removable)
- Files over 500 lines

### 🟢 Low priority / good to know
- Recent TODOs (< 1 month — likely intentional in-progress notes)
- Dead code with blast radius 0 (confirmed unused)
- Files 300–500 lines

### 📊 Summary stats
```
Total markers found:     X
Older than 6 months:     X
Deprecated API usages:   X
Dead code candidates:    X
Files over 300 lines:    X
```

For each finding: `<file>:<line> | <age> | <content> | estimated effort: <trivial/small/medium/large>`
