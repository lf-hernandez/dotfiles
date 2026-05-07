#!/usr/bin/env bash
input=$(cat)

# -- Parse JSON fields --
model_id=$(echo "$input" | jq -r '.model.id // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
used_tokens=$(echo "$input" | jq -r '.context_window.used_tokens // empty')
total_tokens=$(echo "$input" | jq -r '.context_window.total_tokens // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')
rl5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.reset_at // empty')
rl7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.reset_at // empty')

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

# Convert an ISO 8601 reset timestamp to "Xh Ym" countdown; prints nothing if unavailable
fmt_reset() {
  local ts="$1"
  [ -z "$ts" ] && return
  local reset_epoch now_epoch secs_left
  reset_epoch=$(date -d "$ts" +%s 2>/dev/null) || return
  now_epoch=$(date +%s)
  secs_left=$(( reset_epoch - now_epoch ))
  [ "$secs_left" -le 0 ] && return
  local h=$(( secs_left / 3600 ))
  local m=$(( (secs_left % 3600) / 60 ))
  if [ "$h" -gt 0 ]; then
    printf '%dh%02dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
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

  sections+=("$(printf 'ctx %b[%s]\033[00m %s%%%s' "$bar_color" "$bar" "$bar_pct" "$tok_str")")
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

# -- 6. Rate limits (show if >= 25%, include reset countdown) --
rl_parts=()
for limit in "5h:$rl5h:$rl5h_reset" "7d:$rl7d:$rl7d_reset"; do
  label="${limit%%:*}"
  rest="${limit#*:}"
  pct="${rest%%:*}"
  reset_ts="${rest#*:}"

  [ -z "$pct" ] && continue
  [ "$pct" -ge 25 ] 2>/dev/null || continue

  reset_str=$(fmt_reset "$reset_ts")
  if [ -n "$reset_str" ]; then
    rl_parts+=("${label}:${pct}%(${reset_str})")
  else
    rl_parts+=("${label}:${pct}%")
  fi
done
if [ "${#rl_parts[@]}" -gt 0 ]; then
  rl_str=$(IFS=' '; echo "${rl_parts[*]}")
  sections+=("$(printf '\033[00;31mRL %s\033[00m' "$rl_str")")
fi

# -- 7. Session cost (green, only if > $0.00) --
if [ -n "$cost" ]; then
  nonzero=$(echo "$cost > 0.001" | bc -l 2>/dev/null)
  if [ "$nonzero" = "1" ]; then
    cost_fmt=$(printf '$%.2f' "$cost")
    sections+=("$(printf '\033[00;32m%s\033[00m' "$cost_fmt")")
  fi
fi

# -- Join sections with " | " and print --
out=""
for s in "${sections[@]}"; do
  if [ -z "$out" ]; then
    out="$s"
  else
    out="${out} | ${s}"
  fi
done
printf '%b' "$out"
