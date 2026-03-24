#!/usr/bin/env bash
# ~/.claude/scripts/on-session-end.sh
# SessionEnd hook — logs session stats + AI summary to ~/.claude/session-log.jsonl
# Summary is generated via Anthropic API (haiku) in a background process
# so the 60s hook timeout is never hit.

INPUT=$(cat)

# ── Parse SessionEnd payload ──────────────────────────────────────────────────
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id      // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
CWD=$(echo "$INPUT"        | jq -r '.cwd             // empty')
REASON=$(echo "$INPUT"     | jq -r '.reason          // "unknown"')

PROJECT=$(basename "$CWD")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_FILE="$HOME/.claude/session-log.jsonl"

# ── Run everything in background — exit immediately to avoid timeout ──────────
(
  # ── Step 1: Count stats from transcript ────────────────────────────────────
  MESSAGES=0
  COMPACTIONS=0
  SUMMARY="(no transcript)"

  if [ ! -f "$TRANSCRIPT" ] || [ -z "$TRANSCRIPT" ]; then
    # No transcript — write minimal entry and exit
    TEMP_FILES_PATH="/tmp/claude-files-${SESSION_ID}.txt"
    MODIFIED_FILES_JSON="[]"
    if [ -f "$TEMP_FILES_PATH" ]; then
      MODIFIED_FILES_JSON=$(sort -u "$TEMP_FILES_PATH" | jq -Rsc '[split("\n")[] | select(length > 0)]')
      rm -f "$TEMP_FILES_PATH"
    fi
    jq -nc \
      --arg ts      "$TIMESTAMP" \
      --arg sid     "$SESSION_ID" \
      --arg proj    "$PROJECT" \
      --arg cwd     "$CWD" \
      --arg reason  "$REASON" \
      --arg summary "$SUMMARY" \
      --argjson msgs           0 \
      --argjson comps          0 \
      --argjson modified_files "$MODIFIED_FILES_JSON" \
      '{timestamp:$ts,session_id:$sid,project:$proj,cwd:$cwd,reason:$reason,messages:$msgs,compactions:$comps,summary:$summary,modified_files:$modified_files}' \
      >> "$LOG_FILE"
    exit 0
  fi

  MESSAGES=$(grep -c '"role"' "$TRANSCRIPT" 2>/dev/null || echo 0)
  COMPACTIONS=$(grep -c '"subtype":"compact_boundary"' "$TRANSCRIPT" 2>/dev/null || echo 0)

  # ── Step 2: Extract user messages only (keep it cheap) ─────────────────────
  # Parse each line of the JSONL transcript, pick role=human/user content
  USER_TURNS=$(
    while IFS= read -r line; do
      role=$(echo "$line" | jq -r '.message.role // empty' 2>/dev/null)
      if [ "$role" = "human" ] || [ "$role" = "user" ]; then
        # Content can be string or array — handle both
        content=$(echo "$line" | jq -r '
          if .message.content | type == "string" then .message.content
          elif .message.content | type == "array" then
            [.message.content[] | select(.type == "text") | .text] | join(" ")
          else empty
          end
        ' 2>/dev/null)
        [ -n "$content" ] && echo "- $content"
      fi
    done < "$TRANSCRIPT" | head -60  # cap at 60 turns to limit tokens
  )

  if [ -z "$USER_TURNS" ]; then
    SUMMARY="(could not extract conversation)"
  else
    # ── Step 3: Get OAuth token from macOS Keychain ─────────────────────────
    TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
            | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)

    if [ -z "$TOKEN" ]; then
      SUMMARY="(no token available for summarization)"
    else
      # ── Step 4: Call Haiku to summarize ──────────────────────────────────
      PROMPT="You are summarizing a Claude Code session for a developer's personal log.

Project: ${PROJECT}
Session end reason: ${REASON}
Total messages: ${MESSAGES}
Compactions: ${COMPACTIONS}

User prompts from this session:
${USER_TURNS}

Write a concise 2-3 sentence summary of what was worked on and accomplished. Be specific about files, features, bugs, or tasks. No preamble."

      RESPONSE=$(curl -sf --max-time 30 \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -H "anthropic-version: 2023-06-01" \
        -d "$(jq -nc \
          --arg model "claude-haiku-4-5-20251001" \
          --arg prompt "$PROMPT" \
          '{
            model: $model,
            max_tokens: 200,
            messages: [{ role: "user", content: $prompt }]
          }')" \
        "https://api.anthropic.com/v1/messages" 2>/dev/null)

      SUMMARY=$(echo "$RESPONSE" | jq -r '.content[0].text // "(summarization failed)"' 2>/dev/null)
      [ -z "$SUMMARY" ] && SUMMARY="(summarization failed)"
    fi
  fi

  # ── Step 5: Write final log entry ──────────────────────────────────────────
  TEMP_FILES_PATH="/tmp/claude-files-${SESSION_ID}.txt"
  MODIFIED_FILES_JSON="[]"
  if [ -f "$TEMP_FILES_PATH" ]; then
    MODIFIED_FILES_JSON=$(sort -u "$TEMP_FILES_PATH" | jq -Rsc '[split("\n")[] | select(length > 0)]')
    rm -f "$TEMP_FILES_PATH"
  fi
  jq -nc \
    --arg ts      "$TIMESTAMP" \
    --arg sid     "$SESSION_ID" \
    --arg proj    "$PROJECT" \
    --arg cwd     "$CWD" \
    --arg reason  "$REASON" \
    --arg summary "$SUMMARY" \
    --argjson msgs           "$MESSAGES" \
    --argjson comps          "$COMPACTIONS" \
    --argjson modified_files "$MODIFIED_FILES_JSON" \
    '{
      timestamp:      $ts,
      session_id:     $sid,
      project:        $proj,
      cwd:            $cwd,
      reason:         $reason,
      messages:       $msgs,
      compactions:    $comps,
      summary:        $summary,
      modified_files: $modified_files
    }' >> "$LOG_FILE"

) &>/dev/null &

# Exit immediately — background process handles everything
exit 0
