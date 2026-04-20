---
name: test-cases
description: Use when you need to document E2E test cases for a feature or bug fix that can't be covered by unit or integration tests alone. Auto-detects ticket from branch name. Reuses codebase context from /plan if already run; falls back to git diff + explorer when invoked standalone. Outputs to a markdown file by default.
allowed-tools: Agent, Read, Grep, Glob, Bash
---

# Generate E2E Test Case Document

Generate a structured E2E test case document for: `$ARGUMENTS`

## Step 1: Gather inputs

### Ticket (detect in order, stop at first match)
1. Extract `[A-Z]+-\d+` pattern from `$ARGUMENTS` if present
2. Otherwise: `git rev-parse --abbrev-ref HEAD` — extract ticket from branch name
3. Otherwise: ask — "What's the ticket number? (e.g. SOC-1177)"

Derive `TICKET_CODE` by stripping the dash: `SOC-1177` → `SOC1177`.

### Feature name (detect in order, stop at first match)
1. Any non-flag text in `$ARGUMENTS` beyond the ticket
2. Branch name: strip the type prefix and ticket, humanize the remainder
   - `feat/SOC-1177-host-exclusion` → `Host Exclusion`
   - `fix/GH-42-null-scanner-result` → `Null Scanner Result`
3. Most recent commit subject on this branch: `git log main...HEAD --oneline | head -1`
4. If nothing found: ask — "What's the feature or fix name?"

### Optional flags (parse from `$ARGUMENTS` if present)
- `--envs DEV,TEST,PROD` — environments for the tracking table. **Default: DEV, TEST, PROD**
- `--services SMS,BOS` — service prefixes for TC codes. **Default: auto-detect in Step 2**
- `--output <filename>` — write to this file. **Default: `TEST-CASES-{TICKET}.md` in current dir**
- `--inline` — print document in conversation instead of writing a file

## Step 2: Detect context mode

**Check if codebase context already exists in this conversation** — e.g. from a preceding `/plan`, `/issue`, or `/spec` invocation that already spawned the `explorer` agent.

Look for: existing API endpoint listings, DB table names, service names, feature flag names from earlier in the conversation.

### If context already exists (post-plan mode):
→ Skip to Step 3 using the existing context. Do NOT spawn explorer again.

### If no prior context (standalone mode):
Run these in parallel:

**A — Git context:**
```bash
# What branch and recent commits
git rev-parse --abbrev-ref HEAD
git log main...HEAD --oneline 2>/dev/null || git log origin/main...HEAD --oneline 2>/dev/null | head -10

# What files actually changed
git diff main...HEAD --stat 2>/dev/null || git diff origin/main...HEAD --stat 2>/dev/null

# Staged changes (if on main or early in development)
git diff --staged --stat
```

**B — Explorer agent** (if git diff shows meaningful changes OR branch is ahead of main):
Spawn the `explorer` agent:

```
I'm generating E2E test case documentation for: {TICKET} {feature name}

Based on the changed files (from git diff), find:
1. API endpoints — method + path + controller file:line. Include DTO field names and response shape.
2. Database tables — real table names and key columns touched by this feature.
3. Service names / modules — e.g. which microservices or modules own this feature.
4. Feature flags — flag names, what they enable, default state.
5. Error paths — validation errors thrown, HTTP status codes, exact error messages.
6. External integrations — queues (NATS, RabbitMQ), third-party systems, internal APIs called.
7. Regression context — known bugs fixed, NotFoundException crashes, TODO/FIXME markers near changed code.

Focus on: {list of changed files from git diff}
```

Wait for both to complete before proceeding.

## Step 3: Plan test coverage

Reason through the coverage needed before writing a single test case.

**Mandatory for every feature:**
- Happy path — it works
- Input validation — invalid/malformed data rejected with correct error and message
- Edge cases — empty, null, boundary values, zero results, full overlap, no overlap
- Error paths — missing resources (404), permission errors (403), service unavailable
- Regression — if fixing a known bug, at least one TC explicitly marks it

**Additional categories based on what was found:**
- Multi-service integration → per-service TCs + cross-service data flow + failure/fallback
- State mutations → create + read + update + delete lifecycle; idempotency
- Feature flags → behavior with flag ON and with flag OFF
- Snapshot / immutability → state frozen at dispatch time, changes don't affect running jobs
- Async / queue dispatch → what gets published to queue, what happens if queue unavailable

**Organize TCs:**
- Group by service/module (one `###` section per service)
- Within each service, group by phase or category
- Number each group starting from 001, zero-padded to 3 digits
- TC code format: `TC-{TICKET_CODE}-{SERVICE}-{NNN}`

## Step 4: Generate the document

Produce the full markdown using this exact structure:

```
# {TICKET} {Feature Name} — Test Cases

## Summary

| # | Test Case Code | {ENV1} | {ENV2} | {ENV3} |
|---|----------------|--------|--------|--------|
| 1 | TC-{TICKET_CODE}-{SERVICE}-001 | ☐ | ☐ | ☐ |
... one row per TC ...

---

## Test Case Descriptions

### {SERVICE} — {Category} (Phase N)

#### TC-{TICKET_CODE}-{SERVICE}-{NNN}: {Test Case Title}

**Description:** One sentence — what behavior is verified and why it matters.

**Dependencies:** *(omit section if none)*
- Requires TC-...-001 — needs the config_id created there

**Reproduction Flow:**

1. Step description.

   ```bash
   POST /actual/endpoint/path
   Authorization: Bearer {JWT_TOKEN}
   Content-Type: application/json

   {
     "field": "value using real DTO field names"
   }
   ```

2. Save `{resource_id}` from the response.

3. Verify in DB:

   ```sql
   SELECT * FROM actual_table_name WHERE id_column = '{resource_id}';
   ```

**Expected:**
- HTTP 201 Created
- Response contains `resource_id` and `field_name: expected_value`
- DB has N rows in `actual_table_name` with `column = 'value'`
- **Regression note:** *(only for regression TCs)* Previously threw `ErrorClassName: exact error message`

---
```

**Hard rules — violations make the document useless:**
1. No placeholder names in the final output — use real endpoint paths, real table names, real DTO fields. Only `{JWT_TOKEN}`, `{config_id}`, `{scan_id}`, `{org_id}` and similar runtime tokens are acceptable.
2. Real test data over invented data — RFC5737 ranges (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`), well-known IPs (`8.8.8.8`, `1.1.1.1`), or data from the real data reference section.
3. Every TC that mutates state needs a DB verification step.
4. Expected results must be specific and measurable — HTTP status + field values + DB state. Not "it works correctly."
5. Regression TCs must include `**Regression note:**` with the exact error that previously occurred.
6. Feature flag TCs must include `**Note:** Requires feature flag \`flag_name\` enabled` at the top of Reproduction Flow.

## Step 5: Append supporting sections

```
---

## Additional Notes

### Real Data Reference

- **Test IP ranges (RFC5737 — safe for documentation):**
  - `192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`
- **Well-known public IPs:**
  - Google DNS: `8.8.8.8`, `8.8.4.4` | Cloudflare: `1.1.1.1`, `1.0.0.1`

{Append any domain/IP/service-specific real data discovered from codebase or git context}

### Feature Flags

{List each flag: name, what it enables, default state, which TCs require it}

### Excluded / Out-of-Scope

{List test cases considered but excluded — reason: endpoint not implemented, covered by unit tests, deferred to another ticket, etc.}
```

## Step 6: Validate before output

Before writing or printing:
1. Count `#### TC-` headers — must match row count in summary table exactly.
2. Every TC referenced in a "Requires TC-..." must exist in the document.
3. No `{placeholder}` text remains except the approved runtime tokens listed in Step 4.
4. Every TC has: Description, at least one Reproduction Flow step, Expected section.

If any check fails — fix it before output.

## Step 7: Output

**If writing to file** (default unless `--inline` was passed):
```bash
# Write the document to the output file
cat > {output_filename} << 'EOF'
{document content}
EOF
```

Then tell the user:
```
✅ Test cases written to: {output_filename}
   {N} test cases across {M} services ({ENV1}/{ENV2}/{ENV3})

   To start testing: open {output_filename} and replace ☐ with ✅/❌ as you go.
```

**If printing inline** (`--inline` flag):
Print the full document. Do not truncate — print every TC.
