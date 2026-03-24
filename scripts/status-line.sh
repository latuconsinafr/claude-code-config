#!/usr/bin/env bash
# ~/.claude/scripts/status-line.sh
# Claude Code statusline — Nerd Font icons + quota usage
# Requires: jq, git, curl, macOS Keychain

# ── Read stdin JSON from Claude Code ─────────────────────────────────────────
INPUT=$(cat)
DIR=$(echo "$INPUT"             | jq -r '.workspace.current_dir // empty')
MODEL=$(echo "$INPUT"           | jq -r '.model.display_name // empty')
CTX_USED=$(echo "$INPUT"        | jq -r '.context_window.used_percentage // empty')
TRANSCRIPT=$(echo "$INPUT"      | jq -r '.transcript_path        // empty')

# ── ANSI colors ───────────────────────────────────────────────────────────────
CYAN="\033[36m"
BLUE="\033[34m"
PURPLE="\033[35m"
YELLOW="\033[33m"
GREEN="\033[32m"
RED="\033[31m"
DIM="\033[2m"
RESET="\033[0m"

# ── Helper: color by utilization % (green < 50, yellow < 80, red >= 80) ──────
color_used() {
  local val="${1%%.*}"

  if   [ "$val" -ge 80 ] 2>/dev/null; then printf "%s" "$RED"
  elif [ "$val" -ge 50 ] 2>/dev/null; then printf "%s" "$YELLOW"
  else printf "%s" "$GREEN"
  fi
}

# ── Helper: color for compaction count (0=dim, 1-2=yellow, 3+=red) ───────────
color_compactions() {
  local val="$1"

  if   [ "$val" -ge 3 ] 2>/dev/null; then printf "%s" "$RED"
  elif [ "$val" -ge 1 ] 2>/dev/null; then printf "%s" "$YELLOW"
  else printf "%s" "$DIM"
  fi
}

# ── Helper: ISO8601 → "Xh Ym" remaining ──────────────────────────────────────
time_until() {
  local iso="$1"
  local clean="${iso%.*}"; clean="${clean%Z}"
  local target

  # BSD date (macOS)
  target=$(date -u -j -f "%Y-%m-%dT%H:%M:%S" "$clean" +%s 2>/dev/null)

  # GNU date (Linux fallback)
  [ -z "$target" ] && target=$(date -u -d "${clean/T/ }" +%s 2>/dev/null)
  [ -z "$target" ] && return

  local now; now=$(date -u +%s)
  local diff=$(( target - now ))

  [ "$diff" -le 0 ] && echo "soon" && return

  local h=$(( diff / 3600 ))
  local m=$(( (diff % 3600) / 60 ))

  [ "$h" -gt 0 ] && echo "${h}h ${m}m" || echo "${m}m"
}

# ── Count compactions from transcript JSONL ───────────────────────────────────
count_compactions() {
  local path="$1"
  [ -z "$path" ] || [ ! -f "$path" ] && echo 0 && return
  grep -c '"subtype":"compact_boundary"' "$path" 2>/dev/null || echo 0
}

# ── Fetch usage (with 10-min cache) ──────────────────────────────────────────
CACHE_FILE="/tmp/claude-usage-last-good.json"
USAGE_RAW=""

# Reuse cache if fresh (also shared with claudeline if installed)
if [ -f "$CACHE_FILE" ]; then
  cache_age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0) ))
  [ "$cache_age" -lt 600 ] && USAGE_RAW=$(cat "$CACHE_FILE")
fi

if [ -z "$USAGE_RAW" ]; then
  # Extract token from macOS Keychain
  TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
          | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)

  if [ -n "$TOKEN" ]; then
    USAGE_RAW=$(curl -sf --max-time 3 \
      -H "Authorization: Bearer $TOKEN" \
      -H "anthropic-beta: oauth-2025-04-20" \
      "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
    [ -n "$USAGE_RAW" ] && echo "$USAGE_RAW" > "$CACHE_FILE"
  fi
fi

# ── Parse usage fields ────────────────────────────────────────────────────────
FIVE_H_PCT="" FIVE_H_RESET="" SEVEN_D_PCT="" SEVEN_D_RESET=""

if [ -n "$USAGE_RAW" ]; then
  ERR=$(echo "$USAGE_RAW" | jq -r '.error.type // empty' 2>/dev/null)

  if [ -z "$ERR" ]; then
    FIVE_H_PCT=$(echo "$USAGE_RAW"    | jq -r '.five_hour.utilization // empty')
    FIVE_H_RESET=$(echo "$USAGE_RAW"  | jq -r '.five_hour.resets_at   // empty')
    SEVEN_D_PCT=$(echo "$USAGE_RAW"   | jq -r '.seven_day.utilization // empty')
    SEVEN_D_RESET=$(echo "$USAGE_RAW" | jq -r '.seven_day.resets_at   // empty')
  fi
fi

# ── Git info ──────────────────────────────────────────────────────────────────
GIT_BRANCH="" GIT_DIRTY=""
if [ -n "$DIR" ] && cd "$DIR" 2>/dev/null; then
  GIT_BRANCH=$(git -c core.useBuiltinFSMonitor=false rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ -n "$GIT_BRANCH" ] && \
    [ -n "$(git -c core.useBuiltinFSMonitor=false status --porcelain 2>/dev/null)" ] && \
    GIT_DIRTY="*"
fi

# ── Compaction count ──────────────────────────────────────────────────────────
COMPACTIONS=$(count_compactions "$TRANSCRIPT")

# ══ Render statusline ═════════════════════════════════════════════════════════

#  user
printf "${CYAN} $(whoami)${RESET}"

#   directory
printf " in ${BLUE} %s${RESET}" "$(basename "$DIR")"

#  git branch
[ -n "$GIT_BRANCH" ] && printf " on ${PURPLE} %s%s${RESET}" "$GIT_BRANCH" "$GIT_DIRTY"

# 󱙺 model [· % ctx left · 󰕆 compactions]
if [ -n "$MODEL" ]; then
  printf " ${DIM}[${RESET}${YELLOW}󱙺 %s${RESET}" "$MODEL"
 
  # context used% — green=fine, yellow=getting full, red=almost compacting
  if [ -n "$CTX_USED" ]; then
    CTX_COLOR=$(color_used "$CTX_USED")
    CTX_REMAINING=$(( 100 - ${CTX_USED%%.*} ))

    printf " ${DIM}·${RESET} ${CTX_COLOR}%s%% ctx left${RESET}" "$CTX_REMAINING"
  fi
 
  # compaction count — only show if > 0
  if [ "$COMPACTIONS" -gt 0 ] 2>/dev/null; then
    C_COLOR=$(color_compactions "$COMPACTIONS")
    printf " ${DIM}·${RESET} ${C_COLOR}󰕆 %s${RESET}" "$COMPACTIONS"
  fi
 
  printf "${DIM}]${RESET}"
fi

# quota block: (󱑎 12% 5h (2h 30m) · 󰃭 45% 7d (3d 2h))
USAGE_PARTS=()

if [ -n "$FIVE_H_PCT" ]; then
  H_COLOR=$(color_used "$FIVE_H_PCT")
  PCT="${FIVE_H_PCT%%.*}"
  LABEL="󱑎 ${PCT}% 5h"

  if [ -n "$FIVE_H_RESET" ]; then
    R=$(time_until "$FIVE_H_RESET")
    [ -n "$R" ] && LABEL="󱑎 ${PCT}% 5h (${R})"
  fi

  USAGE_PARTS+=("${H_COLOR}${LABEL}${RESET}")
fi

if [ -n "$SEVEN_D_PCT" ]; then
  W_COLOR=$(color_used "$SEVEN_D_PCT")
  PCT="${SEVEN_D_PCT%%.*}"
  LABEL="󰃭 ${PCT}% 7d"

  if [ -n "$SEVEN_D_RESET" ]; then
    R=$(time_until "$SEVEN_D_RESET")
    [ -n "$R" ] && LABEL="󰃭 ${PCT}% 7d (${R})"
  fi

  USAGE_PARTS+=("${W_COLOR}${LABEL}${RESET}")
fi

if [ "${#USAGE_PARTS[@]}" -gt 0 ]; then
  printf " ${DIM}(${RESET}"

  for i in "${!USAGE_PARTS[@]}"; do
    [ "$i" -gt 0 ] && printf "${DIM} · ${RESET}"
    printf "%b" "${USAGE_PARTS[$i]}"
  done

  printf "${DIM})${RESET}"
fi

printf "\n"
