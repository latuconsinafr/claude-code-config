---
name: spec
description: Use before implementing a complex, high-stakes, or cross-cutting feature — produces a full technical specification including data model, API contract, edge cases, and open questions. The planning layer above /plan. Invoke this when /plan alone isn't detailed enough.
allowed-tools: Read, Grep, Glob, Bash
---

# Technical Specification

Produce a full technical specification before any implementation begins.
No code is written during this skill. This is a design document, not a plan.

## Step 1: Understand the feature

Read `$ARGUMENTS` carefully.

Extract:
- **What** — what capability does this add or change?
- **Why** — what problem does it solve? What's the business/user motivation?
- **Who** — which users, systems, or services are affected?
- **Scope** — what is explicitly in scope vs. out of scope?

If any of these are unclear → ask one clarifying question before exploring.

## Step 2: Explore the codebase

Use subagents to map the current state:
- Existing data models relevant to the feature
- Existing API endpoints or service interfaces that will change
- Authentication and authorization patterns in use
- Error handling conventions
- Test patterns and existing coverage in the affected area
- Any prior attempts at this feature (search git log, comments, TODOs)

**Constraint inventory:** note any existing constraints the spec must respect — existing API contracts, database schema limitations, third-party integrations, performance SLAs.

## Step 3: Produce the specification

---

### 🎯 Feature Overview
**Name:** `<feature name>`
**Motivation:** Why is this being built? What problem does it solve?
**Success criteria:** How will we know this feature is working correctly in production?

---

### 📐 Data Model

For each new or modified entity:
```
Entity: <Name>
Fields:
  - <field>: <type> | <constraints> | <description>
  - ...

Indexes:
  - <index definition and reason>

Relationships:
  - <entity> → <entity>: <type> (one-to-many, etc.)
```

For schema migrations: describe UP and DOWN explicitly.
Flag any fields that could contain sensitive data (PII, secrets).

---

### 🔌 API Contract

For each new or modified endpoint:
```
<METHOD> <path>

Auth: <required role/permission or "none">

Request:
  Headers: <any required headers>
  Params:  <path params with types>
  Query:   <query params with types, optional/required>
  Body:    <schema with field types and constraints>

Response:
  200: <schema>
  400: <when and what>
  401: <when>
  403: <when>
  404: <when>
  500: <when>

Rate limiting: <if applicable>
Idempotency: <if applicable>
```

For internal service interfaces (not HTTP): describe the function signature, inputs, outputs, and error types.

---

### 🔐 Security considerations

- Authentication: how is the caller identified?
- Authorization: what permissions are required? What data isolation rules apply?
- Input validation: what must be validated and where?
- Sensitive data: what data is stored/transmitted and how is it protected?
- Audit trail: does this action need to be logged for compliance?

---

### ⚡ Performance considerations

- Expected request volume and data size
- Operations that could be slow (joins, aggregations, external calls)
- Caching strategy if applicable
- Pagination requirements for list endpoints

---

### 🔀 Edge cases

List every non-happy-path scenario and how it should be handled:
- Empty inputs, null values, zero counts
- Concurrent operations (two users acting on the same record simultaneously)
- Partial failures (external service times out mid-operation)
- Large inputs (file uploads, bulk operations)
- Permission boundary cases (user has partial access)

---

### 🧪 Testing plan

- Unit tests: what functions/methods need isolated tests?
- Integration tests: what end-to-end flows must be covered?
- Edge case tests: which edge cases above need explicit test coverage?
- Load/performance tests: are any needed before release?

---

### 🚧 Out of scope

What is explicitly NOT being built in this iteration, to prevent scope creep.

---

### ❓ Open questions

Unresolved decisions that must be made before implementation begins.
For each: what the question is, who needs to decide, and what the options are.

---

### 📦 Dependencies & sequencing

- External services or APIs this depends on
- Other features or changes that must land first
- Teams or people who need to be notified or consulted

---

## Step 4: Confirm the spec

Present the specification and ask:
"Does this spec capture the intent correctly? Any sections to add, change, or remove before implementation begins?"

Do not begin implementation until the spec is explicitly approved.
After approval, use `/plan` to produce the ordered implementation steps from this spec.
