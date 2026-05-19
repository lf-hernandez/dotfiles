#!/usr/bin/env bash
input=$(cat)

# -- Parse JSON fields --
model_id=$(echo "$input" | jq -r '.model.id // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
in_tok=$(echo "$input" | jq -r '.context_window.total_input_tokens // .context_window.used_tokens // empty')
out_tok=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // .context_window.total_tokens // empty')
used_tokens=$(( ${in_tok:-0} + ${out_tok:-0} ))
[ "$used_tokens" = "0" ] && used_tokens=""
total_tokens="$ctx_size"
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')
rl5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // .rate_limits.five_hour.reset_at // empty')
rl7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // .rate_limits.seven_day.reset_at // empty')

# Accumulate sections; join with " | " at the end
sections=()

# -- Helpers --

# Format token count as Xk (e.g. 45231 -> 45k) or raw if < 1000
fmt_tokens() {
  local t="$1"
  [ -z "$t" ] && return
  if [ "$t" -ge 1000 ] 2>/dev/null; then
    printf '%dk' "$(( t / 1000 ))"
  else
    printf '%d' "$t"
  fi
}

# Convert an ISO 8601 reset timestamp to "HH:MM (Xh Ym left)" — local clock + countdown.
# Adds weekday prefix if the reset is on a different calendar day.
fmt_reset() {
  local ts="$1"
  [ -z "$ts" ] && return
  local reset_epoch now_epoch secs_left
  # Field is Unix epoch seconds (per Claude Code docs); fall back to ISO string parsing.
  if [[ "$ts" =~ ^[0-9]+$ ]]; then
    reset_epoch="$ts"
  else
    reset_epoch=$(date -d "$ts" +%s 2>/dev/null) || return
  fi
  now_epoch=$(date +%s)
  secs_left=$(( reset_epoch - now_epoch ))
  [ "$secs_left" -le 0 ] && return

  local today reset_day clock
  today=$(date +%Y-%m-%d)
  reset_day=$(date -d "@$reset_epoch" +%Y-%m-%d)
  if [ "$today" = "$reset_day" ]; then
    clock=$(date -d "@$reset_epoch" +%H:%M)
  else
    clock=$(date -d "@$reset_epoch" +'%a %H:%M')
  fi

  local d=$(( secs_left / 86400 ))
  local h=$(( (secs_left % 86400) / 3600 ))
  local m=$(( (secs_left % 3600) / 60 ))
  local left
  if [ "$d" -gt 0 ]; then
    left=$(printf '%dd%dh' "$d" "$h")
  elif [ "$h" -gt 0 ]; then
    left=$(printf '%dh%02dm' "$h" "$m")
  else
    left=$(printf '%dm' "$m")
  fi
  printf '%s, in %s' "$clock" "$left"
}

# -- 1. Model name (yellow) --
if [ -n "$model_id" ]; then
  short_model=$(echo "$model_id" | sed 's/-[0-9]\{8\}$//')
  sections+=("$(printf '\033[00;33m%s\033[00m' "$short_model")")
fi

# -- 2. Context progress bar + token counts (color-coded) --
if [ -n "$used" ]; then
  bar_pct=$(printf '%.0f' "$used")
  bar_width=24
  filled=$(printf '%.0f' "$(echo "$used * $bar_width / 100" | bc -l)")
  [ "$filled" -gt "$bar_width" ] && filled=$bar_width
  [ "$filled" -lt 0 ] && filled=0
  empty=$(( bar_width - filled ))
  bar=""
  for _ in $(seq 1 "$filled" 2>/dev/null); do bar="${bar}="; done
  for _ in $(seq 1 "$empty"  2>/dev/null); do bar="${bar}-"; done
  if [ "$bar_pct" -ge 80 ] 2>/dev/null; then
    bar_color='\033[00;31m'
  elif [ "$bar_pct" -ge 50 ] 2>/dev/null; then
    bar_color='\033[00;33m'
  else
    bar_color='\033[00;32m'
  fi

  tok_str=""
  used_fmt=$(fmt_tokens "$used_tokens")
  total_fmt=$(fmt_tokens "$total_tokens")
  [ -n "$used_fmt" ] && [ -n "$total_fmt" ] && tok_str=" (${used_fmt}/${total_fmt})"

  # Loud warning when context is at a point where recall degrades.
  # Anthropic's auto-compact triggers around 80%; effective precision slips earlier.
  # Uses reverse video + bold for guaranteed visibility (blink is suppressed by many terminals).
  warn_str=""
  if [ "$bar_pct" -ge 80 ] 2>/dev/null; then
    warn_str=" \033[01;07;31m ⚠ COMPACT OR /clear NOW \033[00m"
  elif [ "$bar_pct" -ge 65 ] 2>/dev/null; then
    warn_str=" \033[01;07;33m ⚠ consider compacting \033[00m"
  fi

  sections+=("$(printf 'ctx %b[%s]\033[00m %s%%%s%b' "$bar_color" "$bar" "$bar_pct" "$tok_str" "$warn_str")")
fi

# -- 3-5. Git info (branch, ahead/behind, stash) --
git_dir=""
if [ -n "$cwd" ]; then
  git_dir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null)
fi

if [ -n "$git_dir" ]; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  if [ -z "$branch" ]; then
    branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    [ -n "$branch" ] && branch="(${branch})"
  fi

  if [ -n "$branch" ]; then
    dirty=""
    git -C "$cwd" diff --quiet 2>/dev/null || dirty="*"
    git -C "$cwd" diff --cached --quiet 2>/dev/null || dirty="*"

    git_branch_str="${branch}${dirty}"

    ahead_behind=""
    upstream=$(git -C "$cwd" rev-parse --abbrev-ref '@{u}' 2>/dev/null)
    if [ -n "$upstream" ]; then
      ahead=$(git -C "$cwd" rev-list --count "@{u}..HEAD" 2>/dev/null)
      behind=$(git -C "$cwd" rev-list --count "HEAD..@{u}" 2>/dev/null)
      [ "$ahead"  -gt 0 ] 2>/dev/null && ahead_behind="${ahead_behind}↑${ahead}"
      [ "$behind" -gt 0 ] 2>/dev/null && ahead_behind="${ahead_behind}↓${behind}"
    fi

    stash_count=$(git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')

    git_section="$(printf '\033[00;36m%s\033[00m' "$git_branch_str")"
    [ -n "$ahead_behind" ] && git_section="${git_section} $(printf '\033[02;36m%s\033[00m' "$ahead_behind")"
    [ "$stash_count" -gt 0 ] 2>/dev/null && git_section="${git_section} $(printf '\033[02;37m[%s stashed]\033[00m' "$stash_count")"
    sections+=("$git_section")
  fi
fi

# -- 6. Session cost (label + green, only if > $0.00) — kept on line 1 --
if [ -n "$cost" ]; then
  nonzero=$(echo "$cost > 0.001" | bc -l 2>/dev/null)
  if [ "$nonzero" = "1" ]; then
    cost_fmt=$(printf 'session cost \033[00;32m$%.2f\033[00m' "$cost")
    sections+=("$cost_fmt")
  fi
fi

# -- 7. Rate limits (rendered on a second line so the status bar doesn't overflow) --
rl_parts=()
for limit in "session:$rl5h:$rl5h_reset" "week:$rl7d:$rl7d_reset"; do
  label="${limit%%:*}"
  rest="${limit#*:}"
  pct="${rest%%:*}"
  reset_ts="${rest#*:}"

  [ -z "$pct" ] && continue

  reset_str=$(fmt_reset "$reset_ts")
  if [ -n "$reset_str" ]; then
    rl_parts+=("${label} ${pct}% (resets ${reset_str})")
  else
    rl_parts+=("${label} ${pct}%")
  fi
done
if [ "${#rl_parts[@]}" -gt 0 ]; then
  rl_str=$(IFS=' • '; echo "${rl_parts[*]}")
  # Color based on highest pct
  max_pct=0
  [ -n "$rl5h" ] && [ "$rl5h" -gt "$max_pct" ] 2>/dev/null && max_pct=$rl5h
  [ -n "$rl7d" ] && [ "$rl7d" -gt "$max_pct" ] 2>/dev/null && max_pct=$rl7d
  if [ "$max_pct" -ge 80 ] 2>/dev/null; then
    rl_color='\033[00;31m'
  elif [ "$max_pct" -ge 50 ] 2>/dev/null; then
    rl_color='\033[00;33m'
  else
    rl_color='\033[00;32m'
  fi
  usage_line=$(printf '%bUsage: %s\033[00m' "$rl_color" "$rl_str")
fi

# -- Join sections with " | " for line 1, then print usage on line 2 --
out=""
for s in "${sections[@]}"; do
  if [ -z "$out" ]; then
    out="$s"
  else
    out="${out} | ${s}"
  fi
done
printf '%b' "$out"
[ -n "${usage_line:-}" ] && printf '\n%b' "$usage_line"
