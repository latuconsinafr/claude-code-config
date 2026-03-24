#!/usr/bin/env bash
# ~/.claude/scripts/on-permission.sh
# PreToolUse hook — notifies when Claude needs permission to run a tool
# Only fires in "default" permission mode (where each tool use requires approval)
# Requires: jq, alerter (brew install vjeantet/tap/alerter)

INPUT=$(cat)

# ── Only notify when user approval is actually required ───────────────────────
PERMISSION_MODE=$(echo "$INPUT" | jq -r '.permission_mode // empty')
case "$PERMISSION_MODE" in
  acceptEdits|dontAsk|bypassPermissions) exit 0 ;;
esac

# ── Parse fields ──────────────────────────────────────────────────────────────
TOOL_NAME=$(echo "$INPUT"  | jq -r '.tool_name  // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')
CWD=$(echo "$INPUT"        | jq -r '.cwd        // empty')
PROJECT=$(basename "$CWD")

# ── Build message describing what Claude wants to do ─────────────────────────
case "$TOOL_NAME" in
  Bash)
    CMD=$(echo "$TOOL_INPUT" | jq -r '.command // empty' | tr -s '\n' ' ' | cut -c1-60)
    MSG="Run: $CMD"
    ;;
  Edit|MultiEdit)
    FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' | xargs basename 2>/dev/null)
    MSG="Edit: $FILE"
    ;;
  Write)
    FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' | xargs basename 2>/dev/null)
    MSG="Write: $FILE"
    ;;
  Read|Glob|Grep|LS)
    exit 0
    ;;
  *)
    MSG="$TOOL_NAME"
    ;;
esac

# ── Send notification ─────────────────────────────────────────────────────────
# Uses --group so repeated tool calls replace the previous notification (no spam)
ICON="$HOME/.claude/claude-icon.png"

if command -v alerter &>/dev/null; then
  alerter \
    --title    "Latuconsinafr x Claude Code" \
    --subtitle "🔐 Permission needed [$PROJECT]" \
    --message  "$MSG" \
    --sound    "Basso" \
    --app-icon "$ICON" \
    --group    "claude-permission" \
    &>/dev/null &
else
  osascript -e "display notification \"$MSG\" with title \"Latuconsinafr x Claude Code\" subtitle \"🔐 Permission needed [$PROJECT]\" sound name \"Basso\""
fi

exit 0
