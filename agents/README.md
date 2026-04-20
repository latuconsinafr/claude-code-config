# Agents

10 specialist subagents that run in isolated context windows, spawned by skills for deep, focused work.

## What are agents?

Agents are:
- PE-level (principal engineer) specialist processors
- Isolated context — they don't consume main conversation window
- Chained by skills — each skill spawns specific agents in sequence
- Defined in frontmatter with tools, model, `disable-model-invocation: true`

Each agent lives in `agents/<name>.md` and is invoked via the `Agent` tool with a task description.

## Agent architecture

```
Skills (orchestrators)
    ↓
Agents (specialists, isolated)
    ↓
Agents can spawn other agents (chains)
```

Example chain:
1. `/debug` skill invokes `debugger` agent
2. Debugger finds root cause and proposes fix
3. Debugger invokes `qa` agent to write regression test
4. Qa writes test, reports back to debugger
5. Debugger returns complete output to skill

## Agents table

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| `architect` | opus | Read, Grep, Glob | Design review — correctness, scalability, reversibility, system implications |
| `debugger` | sonnet | Read, Grep, Glob, Bash, Agent | Root cause analysis — reproduce, isolate, hypothesis, verify, generalize |
| `reviewer` | sonnet | Read, Grep, Glob, Bash, Agent | Code review — correctness, security, perf, patterns, PE lens |
| `qa` | sonnet | Read, Write, Edit, Bash, Grep, Glob | Quality assurance — test strategy, edge cases, behavior verification |
| `refactoring` | sonnet | Read, Write, Edit, Grep, Glob, Bash, Agent | Restructure code without behavior change — blast radius, test baseline, step-by-step |
| `scanner` | haiku | Read, Grep, Glob, Bash | Pattern scanner — tech-debt markers, deprecated APIs, dead code, env var cross-referencing |
| `performance` | haiku | Read, Grep, Glob, Bash | Bottleneck analysis — N+1 queries, hot paths, complexity, trade-offs |
| `researcher` | sonnet | Read, Grep, Glob, Bash, Agent, WebSearch, WebFetch | Technical research — codebase context via explorer + external docs/pitfalls + synthesized findings with confidence tags |
| `explorer` | haiku | Read, Grep, Glob, Bash | Read-only codebase investigation — structure, usage, context gathering |
| `docs` | haiku | Read, Write, Edit, Grep, Glob | Documentation — keep docs in sync, capture decisions, explain why |

## Skill → Agent chains

| Skill | Primary agent | Secondary chain |
|-------|---------------|-----------------|
| `/plan` | `explorer` | → `architect` (conditional) → `/test-cases` (offered or auto if complex + multi-service + API/DB changes) |
| `/spec` | `explorer` | → `architect` (mandatory for validation) |
| `/issue` | `explorer` | (produces plan at end) |
| `/commit` | (none) | — |
| `/review` | `reviewer` | → `performance` (conditional on perf findings) |
| `/pr` | (none) | — |
| `/debug` | `debugger` | → `qa` (mandatory for regression test) |
| `/research` | `researcher` | + `explorer` (spawned by researcher for codebase patterns) |
| `/simplify` | `refactoring` | → `reviewer` (post-refactor validation) |
| `/audit-deps` | (none) | — |
| `/tech-debt` | `scanner` | — |
| `/security` | (none) | — |
| `/env-audit` | `scanner` | — |
| `/onboard` | `explorer` | (produces context summary) |
| `/test-cases` | `explorer` (standalone mode only) | reuses `/plan` context when available; falls back to git diff + explorer |

### Full example chain: `/debug`

```
/debug invoked with bug description
    ↓
spawns debugger agent (sonnet, isolated)
    • Reproduce bug
    • Isolate root cause
    • Form hypothesis with evidence
    • Identify class of bug
    ↓
debugger spawns qa agent (sonnet, isolated)
    • Write regression test from debugger's output
    • Verify test fails with bug present
    • Verify test passes after fix applied
    ↓
qa returns test to debugger
debugger returns full output to /debug skill
/debug skill returns complete result to user
```

## Agent frontmatter format

```yaml
---
name: agentname
description: One-sentence purpose
tools: Read, Grep, Glob, Bash, Agent
model: opus|sonnet|haiku
disable-model-invocation: true
---
```

**Tools:** What the agent can use. Most agents use `Agent` to spawn other agents.

**Model:** Claude model size. Opus for complex design, Sonnet for code work, Haiku for exploration/perf.

**disable-model-invocation:** Set to `true` to prevent accidental loop invocations.

## Adding a new agent

Create `agents/<name>.md` with:

1. **Frontmatter** — name, description, tools, model
2. **Prompt body** — explain the agent's role and methodology
3. **Output format** — structured findings the skill expects back

Example:

```yaml
---
name: myagent
description: Does specialized work on X
tools: Read, Grep, Bash, Agent
model: sonnet
disable-model-invocation: true
---

You are a specialist in X. Your job is...

## How you work
1. Read and understand the task
2. Do the work systematically
3. Report findings in a structured way

## Output format
...
```

---

See [../skills/README.md](../skills/README.md) for skill orchestration and chains.
See [../README.md](../README.md) for full system overview.
See [../CLAUDE.md](../CLAUDE.md) for autonomous invocation rules.
