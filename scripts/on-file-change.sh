#!/usr/bin/env bash
# ~/.claude/scripts/on-file-change.sh
# PostToolUse hook — tracks files modified by Claude per session
# Appends each modified file path to /tmp/claude-files-{session_id}.txt
# on-session-end.sh reads this file to include modified_files in the session log
# Exit 0 always — never blocks

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT"  | jq -r '.tool_name       // empty')

# Only act on file-modifying tools
case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id      // empty')
FILE_PATH=$(echo "$INPUT"  | jq -r '.tool_input.file_path // empty')

if [ -n "$SESSION_ID" ] && [ -n "$FILE_PATH" ]; then
  echo "$FILE_PATH" >> "/tmp/claude-files-${SESSION_ID}.txt"
fi

exit 0
