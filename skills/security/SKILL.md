---
name: security
description: Use when you want a dedicated security review of staged or recently changed files — deeper than the security section in /review. Covers OWASP Top 10, secrets exposure, dependency vulnerabilities, and auth gaps. Run before opening a PR on security-sensitive changes.
allowed-tools: Read, Grep, Glob, Bash
---

# Security Review

Perform a focused security analysis of changed code. Do not modify any files.

## Step 1: Get the target

```bash
git diff --staged
```
If nothing staged:
```bash
git diff HEAD
```
If `$ARGUMENTS` provides a file path → review that file specifically.
If diff is empty and no argument → ask: "What should I review? (staged changes, a specific file, or a path)"

## Step 2: Read full context

For each changed file, read the complete file — not just the diff.
Security issues often live in the surrounding code, not the changed lines.

## Step 3: Security checklist

Work through each category. Report only findings that apply.

### Injection
- **SQL injection** — unparameterized queries: string concatenation or interpolation into SQL
  ```
  `SELECT * WHERE id = ${input}`  ← vulnerable
  db.query('SELECT * WHERE id = $1', [input])  ← safe
  ```
- **Command injection** — user input in shell commands: `exec()`, `spawn()`, `eval()`, `system()`
- **Path traversal** — user-controlled file paths without sanitization: `../` sequences, absolute path injection
- **Template injection** — user input rendered in server-side templates without escaping
- **NoSQL injection** — unvalidated objects passed directly to MongoDB/similar query operators

### Authentication & authorization
- **Missing auth check** — new endpoints or routes without authentication middleware/guard
- **Broken authorization** — accessing records by ID without verifying ownership
  ```
  GET /invoices/:id → fetches invoice without checking invoice.userId === req.user.id
  ```
- **Privilege escalation** — lower-privilege role able to trigger higher-privilege action
- **JWT/token issues** — algorithm confusion, missing expiry check, token not invalidated on logout
- **Password handling** — plaintext storage, weak hashing (MD5/SHA1), missing salt

### Sensitive data exposure
- **Hardcoded secrets** — API keys, tokens, passwords, connection strings in source code
  Patterns: `sk-`, `Bearer `, `password=`, `secret=`, `api_key=`, `-----BEGIN`
- **Secrets in logs** — sensitive fields (password, token, card number, SSN) passed to logger
- **Sensitive data in URLs** — tokens or passwords in query params (appear in server logs)
- **Overly permissive responses** — API returning full user/record objects when only a subset is needed
- **Insecure direct object reference** — exposing internal database IDs directly in responses

### Security misconfigurations
- **CORS** — overly permissive: `Access-Control-Allow-Origin: *` on authenticated endpoints
- **Security headers missing** — CSP, HSTS, X-Frame-Options, X-Content-Type-Options
- **Verbose error messages** — stack traces, internal paths, or DB errors exposed to clients
- **Debug mode in production** — debug flags, development middleware enabled unconditionally
- **Insecure defaults** — new config options defaulting to insecure values

### Input validation
- **Missing validation** — user input used without type, length, or format checks
- **Client-side validation only** — validation exists on frontend but not enforced server-side
- **Mass assignment** — accepting all body fields without an allowlist (e.g., `req.body` directly into DB)

### Dependencies
```bash
# Quick check for known vulnerable packages in the diff context
grep -E "require\(|import.*from" <changed files> 2>/dev/null | \
  grep -v node_modules | sort -u
```
Flag any newly added packages — verify they're not known-malicious or unmaintained.

### Cryptography
- **Weak algorithms** — MD5, SHA1, DES, RC4 for security purposes
- **Insufficient randomness** — `Math.random()` for security tokens (use `crypto.randomBytes()`)
- **Hardcoded IVs or salts** — cryptographic material that should be randomly generated per operation

## Step 4: Output format

Structure findings as:

**🔴 Critical** — exploitable, direct security risk
**🟡 High** — significant risk, should be fixed before merging
**🟢 Medium** — defense-in-depth, worth fixing
**ℹ️ Informational** — best practice, low-risk observation

For each finding:
```
<severity> | <file>:<line> | <vulnerability type>
Issue: <what the problem is>
Impact: <what an attacker could do>
Fix: <specific code change or approach>
```

End with a verdict:
- `✅ No security issues found`
- `⚠️ REVIEW REQUIRED — <N> high, <N> medium findings`
- `🚨 BLOCK — <N> critical findings, do not merge until resolved`

If critical findings exist, list them again at the bottom for immediate reference.
