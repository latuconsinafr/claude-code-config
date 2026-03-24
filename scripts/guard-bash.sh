#!/usr/bin/env bash
# ~/.claude/scripts/guard-bash.sh
# PreToolUse hook — blocks dangerous bash commands
# Exit 2 = block + feed reason back to Claude

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# ── Helpers ───────────────────────────────────────────────────────────────────
block() {
  local reason="$1"
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  jq -nc \
    --arg ts     "$ts" \
    --arg cmd    "$COMMAND" \
    --arg reason "$reason" \
    '{ timestamp: $ts, command: $cmd, reason: $reason }' \
    >> "$HOME/.claude/guard-blocked.log"
  echo "$reason" >&2
  exit 2
}

# Normalize for pattern matching (collapse whitespace, lowercase)
CMD_NORM=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]' | tr -s ' ')

# ── 1. Secret / credential files ─────────────────────────────────────────────
if echo "$COMMAND" | grep -qiE \
  '(^|[[:space:]/])(\.env|\.env\.[a-z]+|\.envrc|secrets?\.[a-z]+|credentials?\.json|\.netrc|\.pgpass|id_rsa|id_ed25519|id_ecdsa|.*\.pem|.*\.key|.*\.p12|.*\.pfx)([[:space:]]|$|")'; then
  block "BLOCKED: Operation involves a sensitive credential/secret file (.env, .pem, .key, id_rsa, etc.). Handle these manually."
fi

# ── 2. Dangerous SQL operations ───────────────────────────────────────────────
# DROP anything
if echo "$CMD_NORM" | grep -qE 'drop[[:space:]]+(table|index|schema|database|column|view|function|trigger|sequence)'; then
  block "BLOCKED: DROP statement detected. Destructive DDL operations must be run manually after human review."
fi

# TRUNCATE
if echo "$CMD_NORM" | grep -qE 'truncate[[:space:]]+(table[[:space:]]+)?[a-z]'; then
  block "BLOCKED: TRUNCATE statement detected. This will permanently delete all rows. Run manually after review."
fi

# DELETE without WHERE (semicolon now optional)
if echo "$CMD_NORM" | grep -qE 'delete[[:space:]]+from[[:space:]]+[a-z_]+[[:space:]]*;?' && \
   ! echo "$CMD_NORM" | grep -qE 'where[[:space:]]'; then
  block "BLOCKED: DELETE FROM without a WHERE clause detected. This will delete all rows. Add a WHERE condition."
fi

# UPDATE without WHERE
if echo "$CMD_NORM" | grep -qE 'update[[:space:]]+[a-z_]+[[:space:]]+set[[:space:]]' && \
   ! echo "$CMD_NORM" | grep -qE 'where[[:space:]]'; then
  block "BLOCKED: UPDATE without a WHERE clause detected. This will update all rows. Add a WHERE condition."
fi

# ALTER TABLE ... DROP COLUMN
if echo "$CMD_NORM" | grep -qE 'alter[[:space:]]+table.+drop[[:space:]]+(column[[:space:]]+)?[a-z]'; then
  block "BLOCKED: ALTER TABLE ... DROP COLUMN detected. Column drops are irreversible. Run manually after review."
fi

# ── 3. Dangerous filesystem operations ───────────────────────────────────────
# rm with recursive + force flags in any combination:
#   -rf, -fr, -r -f, -f -r, --recursive --force, -r --force, etc.
if echo "$CMD_NORM" | grep -qE '(^|[[:space:];|&`(])rm[[:space:]]' && \
   echo "$CMD_NORM" | grep -qE 'rm[[:space:]].{0,80}(-[a-z]*r[a-z]*\b|--recursive)' && \
   echo "$CMD_NORM" | grep -qE 'rm[[:space:]].{0,80}(-[a-z]*f[a-z]*\b|--force\b)'; then
  block "BLOCKED: rm with recursive + force flags detected. Recursive forced deletion must be done manually."
fi

# find -delete or find -exec rm (equivalent to rm -rf on matched files)
if echo "$CMD_NORM" | grep -qE 'find[[:space:]].{0,200}-delete([[:space:]]|$)'; then
  block "BLOCKED: find -delete detected. This recursively deletes matched files. Run manually after review."
fi
if echo "$CMD_NORM" | grep -qE 'find[[:space:]].{0,200}-exec[[:space:]]+rm[[:space:]]'; then
  block "BLOCKED: find -exec rm detected. This recursively deletes matched files. Run manually after review."
fi

# Redirect truncation of source/config files (> but not >>)
if echo "$COMMAND" | grep -qE '>[^>].+\.(ts|tsx|js|jsx|mjs|cjs|json|yaml|yml|toml|sh|bash|zsh|sql|env|conf|config|ini|prisma|py|rb|go|rs|vue|svelte|scss|css|lock)([[:space:]]|$|")'; then
  block "BLOCKED: Output redirection (>) to a source/config file detected. This will truncate the file. Use >> or edit directly."
fi

# chmod 777
if echo "$CMD_NORM" | grep -qE 'chmod[[:space:]]+([-R]+[[:space:]]+)?777'; then
  block "BLOCKED: chmod 777 is a security risk. Use least-privilege permissions instead (e.g. 755, 644)."
fi

# ── 4. Irreversible Git operations ────────────────────────────────────────────
# git push --force
if echo "$CMD_NORM" | grep -qE 'git[[:space:]]+push.+(--force|-f)([[:space:]]|$)'; then
  block "BLOCKED: git push --force detected. Force pushing can overwrite remote history. Run manually if intentional."
fi

# git reset --hard
if echo "$CMD_NORM" | grep -qE 'git[[:space:]]+reset[[:space:]]+--hard'; then
  block "BLOCKED: git reset --hard detected. This will discard all uncommitted changes permanently. Run manually if intentional."
fi

# ── 5. Accidental publish / deploy ───────────────────────────────────────────
# Matches publish anywhere in the command (after &&, ;, etc.)
if echo "$CMD_NORM" | grep -qE '(^|[[:space:];|&`(])(npm|pnpm|yarn)[[:space:]]+publish([[:space:]]|$)'; then
  block "BLOCKED: Package publish command detected. Publishing must be done manually after review."
fi

# ── All checks passed — allow ─────────────────────────────────────────────────
exit 0
