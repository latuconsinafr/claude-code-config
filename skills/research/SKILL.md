---
name: research
description: Use when you need to investigate an unfamiliar library, framework, architectural question, or technical decision — spawns parallel subagents across official docs, codebase patterns, and known pitfalls. Invoke before making technology choices or when the right approach is unclear.
allowed-tools: Bash, Read, Grep, Glob
---

# Research

Research the following topic thoroughly: `$ARGUMENTS`

## Step 1: Decompose the question
Break `$ARGUMENTS` into 2-3 distinct research angles. For example:
- "How does X work?" → official docs + real-world patterns + known pitfalls
- "Should we use X or Y?" → X pros/cons + Y pros/cons + our codebase fit

## Step 2: Launch parallel subagents
Spawn these agents simultaneously — do not wait for one before starting the next:

**Agent 1 — Official docs & current best practices**
- Use context7 if the topic involves a library or framework
- Search for the authoritative/official answer
- Find the recommended pattern as of 2025/2026

**Agent 2 — Codebase exploration**
- Search the current codebase for existing patterns related to the topic
- Find how similar problems have been solved here already
- Identify constraints from the existing architecture

**Agent 3 — Pitfalls & edge cases**
- What are the known gotchas?
- What do people commonly get wrong?
- What are the performance or security implications?

## Step 3: Synthesize findings

Structure the output as:

### 📌 Summary
Two sentences: what is the answer / recommendation?

### 📚 Key findings
Bullet points from each research angle — source each claim.

### ⚡ Recommendation
For this specific codebase and stack:
What is the right approach?

### ⚠️ Pitfalls to avoid
What are the top 2-3 things that could go wrong?

### 🔗 References
Links to relevant docs, issues, or codebase files.

## Step 4: Open questions
List anything that couldn't be resolved through research and needs a decision or experiment.
