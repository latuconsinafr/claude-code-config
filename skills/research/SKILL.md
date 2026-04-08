---
name: research
description: Use when you need to investigate an unfamiliar library, framework, architectural question, or technical decision — spawns the researcher agent which explores the codebase and searches external sources in parallel. Invoke before making technology choices or when the right approach is unclear.
allowed-tools: Agent
---

# Research

Spawn the `researcher` agent with the following task:

```
Research topic: $ARGUMENTS
```

The researcher agent will:
1. Decompose the question into research angles
2. Spawn the `explorer` agent for codebase context (existing patterns, constraints, stack)
3. Search external sources in parallel (official docs, pitfalls, ecosystem notes)
4. Correlate findings — flagging conflicts between external recommendations and the current codebase
5. Return a structured report with `[verified]` / `[inferred]` / `[speculative]` confidence tags

Wait for the researcher agent to return its full report, then present it to the user without modification.
