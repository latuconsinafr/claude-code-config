# Claude Code Configuration

Personal Claude Code config for Farista ([@latuconsinafr](https://github.com/latuconsinafr)) — hooks, skills, agents, and memory system extending Claude Code with principal-engineer workflows.

Published at https://github.com/latuconsinafr/claude-code-config

## Quick start

Clone and symlink:

```bash
git clone https://github.com/latuconsinafr/claude-code-config ~/.claude
# or use directly without symlinking if Claude Code has already discovered ~/.claude
```

Install system dependencies:

```bash
brew install jq git curl vjeantet/tap/alerter
```

Set up Anthropic API OAuth token in macOS Keychain (optional, for quota display and session summaries):

```bash
security add-generic-password -a "Claude Code-credentials" -s "<token_json>" \
  -T /usr/bin/security
```

## Directory structure

| Directory | Purpose |
|-----------|---------|
| **scripts/** | 5 hooks + status line for safety, notifications, context tracking; [details](scripts/README.md) |
| **skills/** | 14 slash-command orchestrators for common workflows ([index](skills/README.md)) |
| **agents/** | 8 specialist subagents for deep work in isolation ([index](agents/README.md)) |
| **projects/** | File-based memory per project — behavioral rules, decisions, context |
| **session-log.jsonl** | Cumulative session history with AI-generated summaries |
| **guard-blocked.log** | Audit log of blocked bash commands by `guard-bash.sh` |
| **CLAUDE.md** | Master reference: principles, rules, autonomous invocation triggers |

## Skills (slash commands)

14 workflow orchestrators. Invoke with `/skillname` or trigger automatically based on rules in CLAUDE.md.

| Skill | What it does |
|-------|--------------|
| `/plan` | Structured implementation plan before coding — spawns `explorer` then `architect` if needed |
| `/spec` | Full technical specification (data model, API contract, edge cases) for complex features |
| `/issue` | Fetch GitHub/Jira issue → explore codebase → produce ready-to-execute plan |
| `/commit` | Generate conventional commit with ticket detection, dirty-diff check, breaking change flag |
| `/review` | Principal engineer code review (correctness, security, perf, tests) — spawns `reviewer` |
| `/pr` | Create GitHub PR with semver-prefixed title and structured body |
| `/debug` | Systematic bug investigation (reproduce → isolate → fix → regression test) — spawns `debugger` + `qa` |
| `/research` | Research unfamiliar libraries, architectural decisions, or technology choices — parallel subagents |
| `/simplify` | Remove over-engineering and dead code without changing behavior — spawns `refactoring` |
| `/audit-deps` | Scan all lockfiles (npm, pip, go, cargo, etc.) for CVEs, outdated majors, license violations |
| `/tech-debt` | Surface TODOs, deprecated APIs, dead code with age and priority |
| `/security` | Dedicated OWASP Top 10 security review (deeper than `/review` security section) |
| `/env-audit` | Audit all env var references vs. sources across code, Docker, CI, config files |
| `/onboard` | Session-start context primer — architecture, recent work, conventions, open issues |

See [skills/README.md](skills/README.md) for invocation details and agent chains.

## Agents (specialist subprocesses)

8 principal-engineer-level agents, isolated context, chained by skills.

| Agent | Model | Purpose |
|-------|-------|---------|
| `architect` | opus | Design review before implementation — correctness, scalability, reversibility, system implications |
| `debugger` | sonnet | Root cause analysis (reproduce → isolate → hypothesis → verify → generalize) |
| `reviewer` | sonnet | Code review — correctness, security, performance, pattern precedent, PE lens |
| `qa` | sonnet | Quality assurance — risk-based test strategy, edge cases, behavior verification |
| `refactoring` | sonnet | Restructure code without behavior change — blast radius check, verify per step |
| `performance` | haiku | Bottleneck analysis — N+1 queries, hot paths, algorithmic complexity |
| `explorer` | haiku | Read-only codebase investigation — structure, usage, context gathering |
| `docs` | haiku | Documentation — keep docs in sync, capture decisions (ADRs), explain why |

See [agents/README.md](agents/README.md) for full chain map and frontmatter format.

## Hooks & status line

[Full details in scripts/README.md](scripts/README.md)

| Hook | Trigger | Purpose |
|------|---------|---------|
| `guard-bash.sh` | PreToolUse (Bash) | Block dangerous commands: secrets access, destructive SQL, `rm -rf`, force-push, etc. |
| `on-permission.sh` | PreToolUse (all tools) | macOS desktop notification when Claude is about to use a permission-required tool |
| `on-stop.sh` | Stop | macOS notification with task summary, turn/tool-call stats, inferred stop reason |
| `on-file-change.sh` | PostToolUse (Edit/Write/MultiEdit) | Track modified files per session for `on-session-end.sh` |
| `on-session-end.sh` | SessionEnd | Log session stats + AI-generated summary to `~/.claude/session-log.jsonl` |
| `status-line.sh` | Custom status line | Display user, project, git branch, model, context %, quota (5h/7d) with color thresholds |

All scripts require `jq`. `on-permission.sh`, `on-stop.sh` require `alerter` (brew install).

## Memory system (dual)

Two complementary systems for knowledge retention.

**File-based** (`projects/<encoded-path>/memory/`)
- Human-readable markdown with `MEMORY.md` index
- YAML frontmatter: `name`, `description`, `type` (user/feedback/project/reference)
- Best for: behavioral rules with *why*, rich context, nuanced guidance
- Write when the memory needs explanation to be applied correctly

**MCP memory** (structured knowledge graph via `mcp__memory__*` tools)
- Entities, observations, relations
- Best for: named facts requiring fast recall (stack, key people, decisions, relationships)
- Write when the memory is a fact about a named entity — person, project, technology, concept

**At session start:**
1. Check `MEMORY.md` in file-based system
2. Run `mcp__memory__search_nodes` for current project/task

## MCP dependencies

| Server | Usage |
|--------|-------|
| `context7` | Fetch current docs for any library/framework before answering tech questions |
| `sequentialthinking` | Enable for complex multi-step problems, architectural decisions, debugging |
| `mcp__memory__*` | Structured knowledge graph — entities, observations, relations |

## System dependencies

All scripts tested on macOS with zsh.

| Tool | Used by | Installation |
|------|---------|--------------|
| `jq` | all scripts | `brew install jq` |
| `git` | guard-bash, status-line | pre-installed |
| `curl` | on-session-end, status-line | pre-installed |
| `alerter` | on-permission, on-stop | `brew install vjeantet/tap/alerter` |

## Autonomous skill invocation

Skills are automatically invoked per CLAUDE.md rules. Key triggers:

- **Start of unfamiliar project** → `/onboard`
- **From a ticket/issue** → `/issue` (not `/plan`)
- **Complex/high-stakes feature** → `/spec` then `/plan`
- **Any non-trivial change** → `/plan` before coding
- **Before commit** → `/commit` (not `git commit`)
- **Before PR** → `/review` then `/pr`
- **Bug/error** → `/debug` (not guessing)
- **Technology choice unclear** → `/research`

See CLAUDE.md for full rules and conditions.

## Project reference

- **Owner:** Farista (latuconsinafr)
- **License:** Check repository for license file
- **Audience:** Personal use; shared for reference and inspiration
- **Status:** Active — hooks and skills in regular use across project work

---

For detailed information on hooks, see [scripts/README.md](scripts/README.md)
For skill invocation and chains, see [skills/README.md](skills/README.md)
For agent roles and specialization, see [agents/README.md](agents/README.md)
For principles and rules, see [CLAUDE.md](CLAUDE.md)
