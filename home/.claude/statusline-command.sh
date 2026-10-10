#!/bin/bash
# Claude Code status line
# Shows: model (+ reasoning effort), context window usage,
# 5-hour rate-limit usage (+ reset countdown), and 7-day rate-limit usage.

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')

# Reasoning effort level (only present when the model supports it)
effort=$(echo "$input" | jq -r '.effort.level // empty')

# Context window usage (used% of the window)
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Claude.ai subscription rate limits
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_reset_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_reset_at=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Format seconds-until as a compact "Xh Ym" / "Xd Yh" string
fmt_remaining() {
  local secs=$1
  [ "$secs" -le 0 ] && { echo "now"; return; }
  local d=$(( secs / 86400 ))
  local h=$(( (secs % 86400) / 3600 ))
  local m=$(( (secs % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then
    printf '%dd %dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then
    printf '%dh %dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

now=$(date +%s)

five_reset_str=""
[ -n "$five_reset_at" ] && five_reset_str=$(fmt_remaining $(( five_reset_at - now )))

week_reset_str=""
[ -n "$week_reset_at" ] && week_reset_str=$(fmt_remaining $(( week_reset_at - now )))

# Colors (dimmed, since the status line renders in a dim style)
DIM=$'\033[2m'
CYAN=$'\033[2;36m'
YELLOW=$'\033[2;33m'
MAGENTA=$'\033[2;35m'
RESET=$'\033[0m'

out="${CYAN}${model}${RESET}"

if [ -n "$effort" ]; then
  out="${out} ${DIM}(${effort})${RESET}"
fi

if [ -n "$ctx_pct" ]; then
  out="${out} ${DIM}|${RESET} ${YELLOW}Ctx: $(printf '%.0f' "$ctx_pct")%${RESET}"
fi

if [ -n "$five_pct" ]; then
  out="${out} ${DIM}|${RESET} ${MAGENTA}5h: $(printf '%.0f' "$five_pct")%${RESET}"
  [ -n "$five_reset_str" ] && out="${out} ${DIM}(⏱ ${five_reset_str})${RESET}"
fi

if [ -n "$week_pct" ]; then
  out="${out} ${DIM}|${RESET} ${MAGENTA}7d: $(printf '%.0f' "$week_pct")%${RESET}"
  [ -n "$week_reset_str" ] && out="${out} ${DIM}(⏱ ${week_reset_str})${RESET}"
fi

printf '%s\n' "$out"
