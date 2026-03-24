# Claude Code Scripts

Four automation scripts that hook into Claude Code to enforce safety, track sessions, and display context information.

## Dependencies at a glance

| Script | Required | Optional | Setup Notes |
|--------|----------|----------|-------------|
| `guard-bash.sh` | `jq` | — | PreToolUse hook; no setup needed |
| `on-stop.sh` | `jq`, `alerter` | — | `brew install vjeantet/tap/alerter`; requires System Settings → Notifications setup |
| `on-session-end.sh` | `jq`, `curl` | Anthropic API token in Keychain | SessionEnd hook; runs in background to avoid 60s timeout |
| `on-file-change.sh` | `jq` | — | PostToolUse hook; no setup needed |
| `status-line.sh` | `jq`, `git`, `curl` | Anthropic API token in Keychain | Custom status line; 10-min cache at `/tmp/claude-usage-last-good.json` |

---

## guard-bash.sh

**Type:** PreToolUse hook
**Purpose:** Blocks dangerous bash commands before execution

Reads stdin JSON containing the bash command (`tool_input.command`), validates it against five categories of dangerous patterns, and exits with code 2 to block unsafe execution. Exit code 2 feeds the block reason back to Claude.

### Blocked command categories

1. **Secret / credential files**
   - Blocks read, write, copy, move, or delete of sensitive files
   - Examples: `.env`, `.env.*`, `.envrc`, `secrets.json`, `.netrc`, `.pgpass`, `id_rsa`, `id_ed25519`, `id_ecdsa`, `*.pem`, `*.key`, `*.p12`, `*.pfx`

2. **Dangerous SQL operations**
   - `DROP TABLE|INDEX|SCHEMA|DATABASE|COLUMN|VIEW|FUNCTION|TRIGGER|SEQUENCE`
   - `TRUNCATE TABLE`
   - `DELETE FROM ... ;` without a WHERE clause
   - `UPDATE ...` without a WHERE clause
   - `ALTER TABLE ... DROP COLUMN`

3. **Destructive filesystem operations**
   - `rm -rf` (any flag ordering: `-rf`, `-fr`, `--force`, `--recursive`)
   - Output redirection (`>`) to source/config files (`.ts`, `.js`, `.json`, `.yaml`, `.yml`, `.sh`, `.sql`, `.env`, `.conf`, `.config`)
   - `chmod 777` (security risk)

4. **Irreversible Git operations**
   - `git push --force` or `git push -f`
   - `git reset --hard`

5. **Accidental publishing**
   - `npm publish`, `pnpm publish`, `yarn publish`

### Behavior

- Exit code `0`: command passes all checks
- Exit code `2`: command blocked; stderr message explains why
- Patterns are normalized (whitespace collapsed, uppercase → lowercase) for matching
- Pattern matching handles varying flag order and spacing

### Audit log

Every blocked command is appended as a JSONL entry to `~/.claude/guard-blocked.log` with fields: `timestamp`, `command`, `reason`.

Read the last 5 blocks:
```bash
tail -5 ~/.claude/guard-blocked.log | jq '.'
```

---

## on-stop.sh

**Type:** Stop hook
**Purpose:** Sends a macOS desktop notification when Claude finishes a task

Reads the Stop hook payload (cwd, transcript_path, last_assistant_message), extracts task stats from the transcript, infers the stop reason, formats a notification, and sends it via `alerter` or `osascript`.

### Parsed payload fields

- `cwd`: working directory (used to derive `$PROJECT = basename`)
- `transcript_path`: path to JSONL session transcript
- `last_assistant_message`: Claude's final message in the session

### Notification title

**Title:** `Latuconsinafr x Claude Code`

### Subtitle inference

The subtitle is inferred from the `last_assistant_message` content:

- **Ends with `?`** → `🧠 Input needed [project]`
- **Otherwise** → `✅ Task complete [project]`

Project name is appended in brackets (derived from `basename $cwd`).

### Notification body

Two-line format:
- **Line 1:** `{turns} turns · {tool_calls} tool calls` (omitted if no tool uses)
- **Line 2:** First 80 characters of last assistant message with markdown stripped, truncated with `…` (omitted if empty)

Markdown removal strips:
- Code blocks (triple backticks)
- Inline code (backticks)
- Bold (`**text**`)
- Emphasis (`*text*`)
- Headings (`# text`)
- Bullet list markers
- Numbered list markers

**Sound:** Glass (macOS notification sound)
**Icon:** `~/.claude/claude-icon.png`

### Stats from transcript

Counts JSON lines in JSONL transcript:
- Tool calls: `grep '"type":"tool_use"'`
- User turns: `grep '"role":"user"'`

### Setup (for rich notifications)

`alerter` provides native macOS notification UI with better styling than `osascript`:

```bash
brew install vjeantet/tap/alerter
```

Then in macOS System Settings:
1. Go to Notifications
2. Find "alerter" in the list
3. Set "Alert Style" to "Alerts" (not "Banners")

### Fallback behavior

If `alerter` is not installed, uses `osascript` (built-in macOS notification, simpler UI). Note: fallback also uses `Latuconsinafr x Claude Code` as title.

### Test manually

```bash
echo '{"cwd":"/Users/you/project","transcript_path":"/dev/null","last_assistant_message":"Updated README and fixed import?"}' | bash on-stop.sh
```

---

## on-session-end.sh

**Type:** SessionEnd hook
**Purpose:** Logs session metadata + AI-generated summary to `~/.claude/session-log.jsonl`

Runs entirely in a background subshell to avoid the 60-second hook timeout. Extracts user turns from the transcript, calls the Anthropic API (Haiku model) to generate a summary, and writes a single JSON line to the session log.

### Logged fields

```json
{
  "timestamp": "2026-03-24T15:30:42Z",
  "session_id": "uuid",
  "project": "project-name",
  "cwd": "/path/to/project",
  "reason": "stop|user_stop|error|...",
  "messages": 42,
  "compactions": 1,
  "summary": "Fixed bug in auth middleware and added unit tests.",
  "modified_files": ["/path/to/file1.ts", "/path/to/file2.js"]
}
```

`modified_files` is a deduplicated array of file paths modified during the session, populated by `on-file-change.sh` via `/tmp/claude-files-{session_id}.txt`.

### Summary generation

1. Counts total messages and compactions in transcript JSONL
2. Extracts up to 60 user turns from transcript (capped to limit API token usage)
3. Retrieves OAuth token from macOS Keychain: `security find-generic-password -s "Claude Code-credentials" -w`
4. POSTs user turns to Anthropic API (claude-haiku-4-5-20251001) with a prompt requesting a 2–3 sentence summary
5. Parses response text and writes to log

### Dependencies

- `jq` (parsing JSON)
- `curl` (API calls; 30s timeout, fails gracefully)
- Anthropic API OAuth token in macOS Keychain (reads automatically; logs gracefully if missing)

### Transcript format (JSONL)

Each line contains a message or annotation. Fields read:
- `role` ("user", "human", or "assistant")
- `content` (string or array of text objects)
- `subtype` ("compact_boundary" to count compactions)

### Fallback behavior

If transcript is missing or token unavailable, summary is set to `"(no transcript)"` or `"(no token available for summarization)"`.

### Read the log

```bash
tail -1 ~/.claude/session-log.jsonl | jq '.'
```

### Background execution

The entire logging logic runs in a background subshell: `( ... ) &>/dev/null &`

This prevents the hook from hitting the 60-second timeout. The hook exits immediately (exit code 0) without waiting for the background process.

---

## status-line.sh

**Type:** Custom Claude Code status line
**Purpose:** Displays working context, model, and quota information in a single line

Reads stdin JSON from Claude Code (`workspace.current_dir`, `model.display_name`, `context_window.used_percentage`, `transcript_path`), fetches quota data from the Anthropic API, and renders a formatted status line with ANSI colors and Nerd Font icons.

### Display format

```
👤 farista in 📁 project on 💜 main* [󱙺 Sonnet · 45% ctx left · 󰕆 2] (󱑎 12% 5h (2h 30m) · 󰃭 45% 7d (3d 2h))
```

Breakdown:
- **User:** `whoami`
- **Directory:** `basename $cwd`
- **Git branch:** current branch (shown as `branch*` if dirty/uncommitted changes)
- **Model context:** `[󱙺 ModelName · X% ctx left · 󰕆 N]`
  - Context percentage = 100% minus `context_window.used_percentage`
  - Compaction count = count of `"subtype":"compact_boundary"` in transcript JSONL (only shown if > 0)
- **Quota:** `(󱑎 X% 5h (Yh Zm) · 󰃭 X% 7d (Yd Zh))`
  - 5-hour rolling quota with time until reset
  - 7-day rolling quota with time until reset

### ANSI color thresholds

| Metric | <50% | 50–79% | ≥80% |
|--------|------|--------|------|
| Context usage | Green | Yellow | Red |
| 5h quota | Green | Yellow | Red |
| 7d quota | Green | Yellow | Red |
| Compactions | Dim | Yellow (≥1) | Red (≥3) |

### Quota data source

Fetches from Anthropic API endpoint: `https://api.anthropic.com/api/oauth/usage`

**Header:** `Authorization: Bearer $TOKEN`
**Header:** `anthropic-beta: oauth-2025-04-20`
**Cached:** 10 minutes at `/tmp/claude-usage-last-good.json`

Token is extracted from macOS Keychain:
```bash
security find-generic-password -s "Claude Code-credentials" -w | jq -r '.claudeAiOauth.accessToken'
```

### Caching

10-minute cache at `/tmp/claude-usage-last-good.json` prevents excessive API calls. Cache is:
- Reused if modification time is < 600 seconds old
- Overwritten if fresh API data is retrieved
- Shared with other tools (e.g., `on-session-end.sh`)

If cache is stale or empty, the script fetches new data from the API. If the API call times out (3s max) or token is unavailable, quota display is omitted.

### Test manually

From CLAUDE.md, the echo pipe command:
```bash
echo '{"workspace":{"current_dir":"'"$PWD"'"},"model":{"display_name":"Sonnet"},"context_window":{"used_percentage":42}}' | bash status-line.sh
```

This renders a minimal status line without quota (since no token is in the test payload).

### Dependencies

- `jq` (JSON parsing)
- `git` (branch info; returns empty if not in a repo)
- `curl` (API calls, 3s timeout; gracefully omits quota if unavailable)
- `date` (BSD on macOS; also supports GNU `date` fallback for Linux)
- Anthropic API OAuth token in macOS Keychain (optional; quota omitted if unavailable)

---

## on-file-change.sh

**Type:** PostToolUse hook
**Purpose:** Tracks files modified by Claude per session

Fires on Edit, Write, and MultiEdit tools only (exits 0 silently for all others). For each matching tool invocation, appends the file path to `/tmp/claude-files-{session_id}.txt`.

### Flow

1. **Fires on:** Edit, Write, MultiEdit only
2. **Reads:** `session_id` and `file_path` from PostToolUse payload
3. **Writes:** Each modified file path to `/tmp/claude-files-{session_id}.txt`
4. **Exit:** Always exits 0 (never blocks)

### Integration with on-session-end.sh

When the session ends, `on-session-end.sh` reads this temp file, deduplicates the paths (via `sort -u`), converts to a JSON array, and includes it as `modified_files` in the session log JSONL entry. The temp file is then deleted.

### Dependencies

- `jq` (reading JSON payload)

### No setup needed

This hook runs automatically with no configuration or installation required.
