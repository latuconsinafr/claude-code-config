---
name: env-audit
description: Use when you want to audit environment variable usage — scans the entire codebase for all env var references across all sources (code, Docker, CI, config files) and flags anything undocumented or inconsistent. Works for any stack and any env var pattern.
allowed-tools: Read, Grep, Glob, Bash
---

# Environment Variable Audit

Scan all env var references and all env var sources. Cross-reference and surface gaps.
Do not modify any files — this is a read-only audit.

## Step 1: Detect the stack

```bash
ls package.json go.mod Cargo.toml requirements.txt Gemfile pyproject.toml 2>/dev/null
ls Dockerfile docker-compose.yml docker-compose*.yml 2>/dev/null
ls .github/workflows/*.yml .gitlab-ci.yml Jenkinsfile 2>/dev/null
ls serverless.yml terraform.tfvars *.tf 2>/dev/null
```

This determines which code patterns and config files to scan.

## Step 2: Scan all env var references in code

Find every place the codebase reads an environment variable:

```bash
# Node / JS / TS
grep -rn "process\.env\.\w\+" \
  --include="*.ts" --include="*.js" --include="*.mjs" --include="*.cjs" \
  --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build \
  . 2>/dev/null | grep -oE "process\.env\.[A-Z_]+" | sort -u

# Python
grep -rn "os\.environ\|os\.getenv\|environ\[" \
  --include="*.py" . 2>/dev/null | \
  grep -oE "(os\.environ\.get\(|os\.getenv\(|environ\[)['\"]([A-Z_]+)" | \
  grep -oE "[A-Z_]{2,}" | sort -u

# Go
grep -rn "os\.Getenv\|os\.LookupEnv" \
  --include="*.go" . 2>/dev/null | \
  grep -oE '"[A-Z_]+"' | tr -d '"' | sort -u

# Rust
grep -rn "env!\|std::env::var\|std::env::var_os" \
  --include="*.rs" . 2>/dev/null | \
  grep -oE '"[A-Z_]+"' | tr -d '"' | sort -u

# Shell scripts
grep -rn '\$[A-Z_]\{2,\}\|\${[A-Z_]\{2,\}}' \
  --include="*.sh" --include="*.bash" --include="*.zsh" \
  . 2>/dev/null | grep -oE '\$\{?[A-Z_]+\}?' | tr -d '${}' | sort -u

# Generic fallback — any ALL_CAPS_VARIABLE pattern in configs
grep -rn '[A-Z][A-Z_]\{2,\}=' \
  --include="*.env*" --include="*.conf" --include="*.config" \
  . 2>/dev/null | grep -oE '^[A-Z_]+' | sort -u
```

Collect all unique variable names referenced in code.

## Step 3: Scan all env var sources

Find every place env vars are defined or declared:

```bash
# .env files (all variants)
find . -name ".env*" -not -path "*/node_modules/*" -not -path "*/.git/*" \
  2>/dev/null | xargs grep -h "^[A-Z_]" 2>/dev/null | \
  grep -oE "^[A-Z_]+" | sort -u

# Docker
grep -E "^ENV |^ARG " Dockerfile* 2>/dev/null | grep -oE "[A-Z_]+" | sort -u
grep -E "^\s+- [A-Z_]+=\|environment:" docker-compose*.yml 2>/dev/null | \
  grep -oE "[A-Z_]+=" | tr -d '=' | sort -u

# GitHub Actions
grep -E "^\s+[A-Z_]+:" .github/workflows/*.yml 2>/dev/null | \
  grep -oE "[A-Z_]{2,}" | sort -u

# GitLab CI
grep -E "^\s+[A-Z_]+:" .gitlab-ci.yml 2>/dev/null | \
  grep -oE "[A-Z_]{2,}" | sort -u

# Terraform / serverless
grep -E "[A-Z_]+\s*=" terraform.tfvars *.tf serverless.yml 2>/dev/null | \
  grep -oE "^[A-Z_]+" | sort -u

# .env.example / .env.sample (documentation files)
find . -name ".env.example" -o -name ".env.sample" -o -name ".env.template" \
  2>/dev/null | xargs grep -h "^[A-Z_]" 2>/dev/null | \
  grep -oE "^[A-Z_]+" | sort -u
```

## Step 4: Cross-reference

Compare the two lists:

**Referenced in code but not defined/documented anywhere:**
→ Missing env var — will cause runtime error or silent undefined behavior

**Defined in sources but never referenced in code:**
→ Possibly stale/unused — can be removed to reduce configuration surface

**Referenced in code and defined in sources but missing from `.env.example`:**
→ Documentation gap — new developer won't know this is required

**Defined with different names across sources:**
→ Naming inconsistency — e.g., `DATABASE_URL` in code but `DB_URL` in Docker

## Step 5: Produce report

### 🔴 Missing — referenced in code, not defined anywhere
```
VAR_NAME
  Referenced in: src/config.ts:12, src/database.ts:8
  Not found in: .env, .env.example, docker-compose.yml, CI configs
  Risk: runtime error / undefined behavior
```

### 🟡 Undocumented — defined in sources, missing from .env.example
```
VAR_NAME
  Defined in: docker-compose.yml
  Missing from: .env.example
  Action: add to .env.example with description and example value
```

### 🟢 Possibly stale — defined but never referenced in code
```
VAR_NAME
  Defined in: .env.example, docker-compose.yml
  Not found in any code files
  Action: verify with git log, then remove if confirmed unused
```

### ⚠️ Naming inconsistencies
```
DATABASE_URL (in code) vs DB_URL (in docker-compose.yml)
  Action: align to one name
```

### ✅ Clean
Variables that are referenced in code, defined in sources, and documented in `.env.example`.

### 📊 Summary
```
Total env vars referenced in code:  X
Fully documented:                   X
Missing definitions:                X  ← must fix
Undocumented:                       X  ← should fix
Possibly stale:                     X  ← investigate
```
