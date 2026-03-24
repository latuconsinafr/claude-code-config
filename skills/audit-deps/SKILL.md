---
name: audit-deps
description: Use when you want to audit project dependencies — scans all lockfiles for CVEs, outdated major versions, and license violations. Run before releases or periodically as a health check.
allowed-tools: Bash, Read, Glob
---

# Dependency Audit

Scan all project dependencies for security vulnerabilities, outdated major versions, and license issues.

## Step 1: Detect package managers and lockfiles

Scan the project root and workspaces for all package managers in use:

```bash
# Node
ls package.json package-lock.json yarn.lock pnpm-lock.yaml 2>/dev/null
# Python
ls requirements.txt requirements*.txt Pipfile.lock poetry.lock 2>/dev/null
# Go
ls go.mod go.sum 2>/dev/null
# Rust
ls Cargo.toml Cargo.lock 2>/dev/null
# Ruby
ls Gemfile Gemfile.lock 2>/dev/null
# Monorepo workspaces
find . -name "package.json" -not -path "*/node_modules/*" -maxdepth 3 2>/dev/null
```

Run all applicable audits. Do not skip a package manager just because it's not the primary one.

## Step 2: Security vulnerabilities

Run the native audit tool for each detected package manager:

**Node (npm/yarn/pnpm):**
```bash
npm audit --json 2>/dev/null
# or
yarn audit --json 2>/dev/null
# or
pnpm audit --json 2>/dev/null
```

**Python:**
```bash
pip-audit --format json 2>/dev/null
# fallback:
safety check --json 2>/dev/null
```

**Go:**
```bash
govulncheck ./... 2>/dev/null
```

**Rust:**
```bash
cargo audit --json 2>/dev/null
```

**Ruby:**
```bash
bundle audit check --update 2>/dev/null
```

For each vulnerability found, extract:
- Package name and current version
- CVE ID and severity (critical / high / medium / low)
- Affected versions and fixed version
- Whether a fix is available

## Step 3: Outdated major versions

Check for packages on outdated major versions (breaking change territory):

**Node:**
```bash
npm outdated --json 2>/dev/null
```

Filter for packages where `current` major < `latest` major (e.g., `"3.x.x"` → `"4.x.x"`).
Minor/patch outdated packages are noise — only flag major version gaps.

**Python:**
```bash
pip list --outdated --format json 2>/dev/null
```

**Go:**
```bash
go list -u -m all 2>/dev/null
```

## Step 4: License scan

Check for licenses that may conflict with your project's license or usage:

**Node:**
```bash
npx license-checker --json --production 2>/dev/null
```

Flag packages with:
- **Copyleft licenses** (GPL, AGPL, LGPL) in a non-open-source project — may require your code to be open-sourced
- **Unknown or unlicensed** packages — legal risk
- **Licenses requiring attribution** (MIT, Apache 2.0 with NOTICE) — ensure compliance

## Step 5: Produce prioritized report

### 🔴 Critical — act immediately
CVEs with critical/high severity that have a fix available.
Format: `<package>@<current> → <fixed> | CVE-XXXX-XXXX | <one-line description>`

### 🟡 Should address
- High/medium CVEs without an immediate fix (monitor for patch)
- Major version gaps on core dependencies (framework, ORM, auth library)
- Copyleft license conflicts

### 🟢 Good to know
- Low severity CVEs
- Minor/patch outdated packages
- Attribution-required licenses (ensure compliance, not a blocker)

### ✅ Clean
Categories with no findings — call them out explicitly so you know what was checked.

## Step 6: Suggested actions

For each 🔴 finding, provide the exact command to fix it:
```bash
npm install <package>@<fixed-version>
# or
pip install "<package>>=<fixed-version>"
```

For major version upgrades, note: "Review changelog for breaking changes before upgrading."
