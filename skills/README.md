# Skills

14 slash-command orchestrators that automate workflows and delegate specialist work to agents.

## What are skills?

Skills are workflow templates that:
- Spawn agents to do deep work in isolation
- Gather context before implementation starts
- Enforce discipline (e.g., plan before coding, review before PR)
- Keep the main conversation clean and focused

Each skill lives in `skills/<name>/SKILL.md` with YAML frontmatter (name, description, allowed-tools) and a markdown prompt body using `$ARGUMENTS` for user input.

## How to invoke skills

**Explicit invocation:**
```
/skillname <arguments>
```

**Natural language** (Claude may infer):
```
"Let me write an implementation plan for..."
→ `/plan` inferred and invoked

"I need to debug this test failure..."
→ `/debug` inferred and invoked
```

**Autonomous invocation** (rules in CLAUDE.md):
- Start of unfamiliar project → `/onboard`
- Starting ticket/issue work → `/issue`
- Before complex implementation → `/spec` + `/plan`
- Before committing → `/commit`
- Before opening PR → `/review` + `/pr`
- Encountering a bug → `/debug`

## Skills → Agents relationship

Skills are **orchestrators**. Most delegate to specialist agents for the heavy work. For example:

- `/plan` spawns `explorer` (map codebase) → optionally `architect` (validate design)
- `/review` spawns `reviewer` (principal engineer review)
- `/debug` spawns `debugger` (root cause) then `qa` (regression test)
- `/research` spawns parallel agents (docs, explorer, pitfalls)
- `/simplify` spawns `refactoring` (structured refactoring with blast radius checks)

Agents run in isolated context windows, keeping main conversation uncluttered.

## Skills table

| Skill | Slash | Spawns | Purpose |
|-------|-------|--------|---------|
| Plan | `/plan` | `explorer`, optionally `architect` | Structured implementation plan before any coding |
| Spec | `/spec` | `explorer`, `architect` | Full technical specification (data model, API, edge cases) |
| Issue | `/issue` | `explorer` | Fetch GitHub/Jira issue → explore codebase → produce plan |
| Commit | `/commit` | — | Generate conventional commit with ticket, type, breaking-change detection |
| Review | `/review` | `reviewer` | Principal engineer code review (correctness, security, perf) |
| PR | `/pr` | — | Create GitHub PR with semver prefix and filled template |
| Debug | `/debug` | `debugger`, `qa` | Systematic debug (reproduce → isolate → fix → regression test) |
| Research | `/research` | `explorer`, custom research agents | Investigate library, architecture, or technology choice |
| Simplify | `/simplify` | `refactoring`, optionally `reviewer` | Remove over-engineering and dead code |
| Audit Deps | `/audit-deps` | — | Scan all lockfiles for CVEs, outdated majors, license violations |
| Tech Debt | `/tech-debt` | — | Surface TODOs, deprecated APIs, dead code with age |
| Security | `/security` | — | OWASP Top 10 security review (deeper than `/review` section) |
| Env Audit | `/env-audit` | — | Audit env var references vs. sources across all config |
| Onboard | `/onboard` | `explorer` | Prime context: architecture, recent work, conventions, open work |

## Adding a new skill

Create `skills/<name>/SKILL.md` with frontmatter and prompt:

```yaml
---
name: skillname
description: One-line description of what this skill does
allowed-tools: Read, Grep, Bash, Agent, Write
---

# Skill Title

Your prompt body using $ARGUMENTS for user input...
```

**Allowed tools:**
- Read-only: `Read`, `Grep`, `Glob`
- Bash operations: `Bash`
- File changes: `Write`, `Edit`, `MultiEdit`
- Subagent delegation: `Agent`

---

See [../agents/README.md](../agents/README.md) for agent specialization and chains.
See [../CLAUDE.md](../CLAUDE.md) for autonomous invocation rules.
