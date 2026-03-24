---
name: research
description: Use when you need to investigate an unfamiliar library, framework, architectural question, or technical decision — spawns parallel subagents across official docs, codebase patterns, and known pitfalls. Invoke before making technology choices or when the right approach is unclear.
allowed-tools: Bash, Read, Grep, Glob
---

# Research

Research the following topic thoroughly: `$ARGUMENTS`

## Step 1: Decompose the question

Break `$ARGUMENTS` into 2–3 distinct research angles. For example:
- "How does X work?" → official docs + real-world patterns + known pitfalls
- "Should we use X or Y?" → X pros/cons + Y pros/cons + fit with current codebase
- "What's wrong with Z?" → known bugs + version history + community workarounds

Determine which agents to spawn based on the question type:
- **Always spawn:** Agent 1 (official docs)
- **Spawn if topic relates to an existing codebase pattern:** Agent 2 (codebase exploration)
- **Always spawn:** Agent 3 (pitfalls and edge cases)

## Step 2: Launch parallel subagents

Spawn the applicable agents simultaneously:

**Agent 1 — Official docs & current best practices**
- For libraries/frameworks: use context7 MCP to get current, version-specific documentation
  - First: `mcp__context7__resolve-library-id` to get the library ID
  - Then: `mcp__context7__query-docs` with a specific query
- For current events, recent releases, or ecosystem news: use WebSearch
- Find the authoritative/official answer for the current version
- Note the version the documentation covers

**Agent 2 — Codebase exploration** *(only if the topic relates to existing code)*

Spawn the `explorer` agent with:
```
Find all existing patterns in this codebase related to: <topic>
Specifically:
- How has this problem (or similar problems) been solved here before?
- What constraints does the existing architecture impose?
- Check package.json / go.mod / Cargo.toml for the stack and versions in use
```

**Agent 3 — Pitfalls & edge cases**
- What are the known gotchas with this approach?
- What do people commonly get wrong?
- What are the performance, security, or reliability implications?
- Search for GitHub issues, Stack Overflow threads, or postmortems related to this

## Step 3: Synthesize findings

Structure the output as:

### 📌 Summary
Two sentences: what is the answer or recommendation?

### 📚 Key findings
Bullet points from each research angle. For each finding, tag its confidence:
- `[verified]` — confirmed in official docs or source code
- `[inferred]` — reasonable conclusion from evidence, not directly stated
- `[speculative]` — plausible but unconfirmed, needs validation

Also note source freshness where relevant: "(docs for v3.2, project uses v3.1 — check changelog for differences)"

### ⚡ Recommendation
Given the current codebase, stack, and constraints (inferred from the project files):
What is the right approach, and why?

### ⚠️ Pitfalls to avoid
The top 2–3 things that could go wrong with the recommended approach.

### ❓ What we don't know
Findings that could not be resolved through research — things that require an experiment, a decision, or more context to answer. Be explicit about gaps rather than filling them with speculation.

### 🔗 References
Links or file paths to relevant docs, issues, or codebase locations.
