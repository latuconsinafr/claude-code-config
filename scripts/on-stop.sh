#!/usr/bin/env bash
# ~/.claude/scripts/on-stop.sh
# Stop hook — sends a macOS desktop notification when Claude stops
# Requires: jq, alerter (brew install vjeantet/tap/alerter)

INPUT=$(cat)

# ── Parse fields (official Stop hook payload) ─────────────────────────────────
DIR=$(echo "$INPUT"        | jq -r '.cwd                    // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path        // empty')
LAST_MSG=$(echo "$INPUT"   | jq -r '.last_assistant_message // empty')
PROJECT=$(basename "$DIR")

# ── Stats from transcript ─────────────────────────────────────────────────────
TOOL_USES=0; TURNS=0
if [ -f "$TRANSCRIPT" ]; then
  TOOL_USES=$(grep -ac '"type":"tool_use"' "$TRANSCRIPT" 2>/dev/null | tr -d '[:space:]')
  TURNS=$(grep -ac '"role":"user"'         "$TRANSCRIPT" 2>/dev/null | tr -d '[:space:]')
  TOOL_USES=${TOOL_USES:-0}
  TURNS=${TURNS:-0}
fi

# ── Summary: strip markdown from last assistant message ───────────────────────
SUMMARY=""
if [ -n "$LAST_MSG" ]; then
  SUMMARY=$(printf '%s' "$LAST_MSG" \
    | tr -s '\n' ' '              \
    | sed 's/```[^`]*```//g'      \
    | sed 's/`[^`]*`//g'          \
    | sed 's/\*\*[^*]*\*\*//g'    \
    | sed 's/\*//g'               \
    | sed 's/#\+ //g'             \
    | sed 's/ - / /g; s/^- //g'   \
    | sed 's/[0-9]\+\. / /g'      \
    | tr -s ' '                   \
    | sed 's/^ //; s/ $//'        \
    | cut -c1-80)
fi

# ── Infer stop reason from last message (no stop_reason in Stop hook payload) ─
if printf '%s' "$LAST_MSG" | grep -qE '\?[[:space:]]*$'; then
  SUBTITLE="🧠 Input needed [$PROJECT]"
else
  SUBTITLE="✅ Task complete [$PROJECT]"
fi

# ── Build notification body ───────────────────────────────────────────────────
# Line 1: stats  |  Line 2: plain-text summary
STATS=""
[ "${TOOL_USES:-0}" -gt 0 ] 2>/dev/null && STATS="${TURNS} turns · ${TOOL_USES} tool calls"

BODY="$STATS"
[ -n "$STATS" ] && [ -n "$SUMMARY" ] && BODY="${STATS}"$'\n'"${SUMMARY}…"
[ -z "$STATS" ] && [ -n "$SUMMARY" ] && BODY="${SUMMARY}…"

# ── Send notification ─────────────────────────────────────────────────────────
ICON="$HOME/.claude/claude-icon.png"

if command -v alerter &>/dev/null; then
  alerter \
    --title    "Latuconsinafr x Claude Code" \
    --subtitle "$SUBTITLE" \
    --message  "$BODY" \
    --sound    "Glass" \
    --app-icon  "$ICON" \
    --group    "claude-stop" \
    &>/dev/null &
else
  osascript -e "display notification \"$BODY\" with title \"Latuconsinafr x Claude Code\" subtitle \"$SUBTITLE\" sound name \"Glass\""
fi

exit 0
