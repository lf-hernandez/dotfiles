#!/usr/bin/env bash
input=$(cat)

# -- Parse JSON fields --
model_id=$(echo "$input" | jq -r '.model.id // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')
rl5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Accumulate sections; join with " | " at the end
sections=()

# -- 1. Model name (yellow) --
# Use the model id directly (e.g. claude-sonnet-4-6); strip date suffix for brevity
if [ -n "$model_id" ]; then
  # Strip trailing -YYYYMMDD date stamp if present (e.g. claude-3-5-sonnet-20241022 -> claude-3-5-sonnet)
  short_model=$(echo "$model_id" | sed 's/-[0-9]\{8\}$//')
  sections+=("$(printf '\033[00;33m%s\033[00m' "$short_model")")
fi

# -- 2. Context progress bar (color-coded) --
if [ -n "$used" ]; then
  bar_pct=$(printf '%.0f' "$used")
  bar_width=24
  filled=$(printf '%.0f' "$(echo "$used * $bar_width / 100" | bc -l)")
  # Clamp filled to [0, bar_width]
  [ "$filled" -gt "$bar_width" ] && filled=$bar_width
  [ "$filled" -lt 0 ] && filled=0
  empty=$(( bar_width - filled ))
  bar=""
  for _ in $(seq 1 "$filled" 2>/dev/null); do bar="${bar}="; done
  for _ in $(seq 1 "$empty"  2>/dev/null); do bar="${bar}-"; done
  if [ "$bar_pct" -ge 80 ] 2>/dev/null; then
    bar_color='\033[00;31m'   # red
  elif [ "$bar_pct" -ge 50 ] 2>/dev/null; then
    bar_color='\033[00;33m'   # yellow
  else
    bar_color='\033[00;32m'   # green
  fi
  sections+=("$(printf 'ctx %b[%s]\033[00m %s%%' "$bar_color" "$bar" "$bar_pct")")
fi

# -- 3-5. Git info (branch, ahead/behind, stash) -- only when inside a git repo --
# Use cwd from JSON so git runs in the right directory
git_dir=""
if [ -n "$cwd" ]; then
  git_dir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null)
fi

if [ -n "$git_dir" ]; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  # Handle detached HEAD
  if [ -z "$branch" ]; then
    branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    [ -n "$branch" ] && branch="(${branch})"
  fi

  if [ -n "$branch" ]; then
    # Dirty indicator: unstaged or staged changes
    dirty=""
    git -C "$cwd" diff --quiet 2>/dev/null || dirty="*"
    git -C "$cwd" diff --cached --quiet 2>/dev/null || dirty="*"

    git_branch_str="${branch}${dirty}"

    # Ahead / behind upstream
    ahead_behind=""
    upstream=$(git -C "$cwd" rev-parse --abbrev-ref '@{u}' 2>/dev/null)
    if [ -n "$upstream" ]; then
      ahead=$(git -C "$cwd" rev-list --count "@{u}..HEAD" 2>/dev/null)
      behind=$(git -C "$cwd" rev-list --count "HEAD..@{u}" 2>/dev/null)
      [ "$ahead"  -gt 0 ] 2>/dev/null && ahead_behind="${ahead_behind}↑${ahead}"
      [ "$behind" -gt 0 ] 2>/dev/null && ahead_behind="${ahead_behind}↓${behind}"
    fi

    # Stash count
    stash_count=$(git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')

    # Build git section string
    git_section="$(printf '\033[00;36m%s\033[00m' "$git_branch_str")"
    [ -n "$ahead_behind" ] && git_section="${git_section} $(printf '\033[02;36m%s\033[00m' "$ahead_behind")"
    [ "$stash_count" -gt 0 ] 2>/dev/null && git_section="${git_section} $(printf '\033[02;37m[%s stashed]\033[00m' "$stash_count")"
    sections+=("$git_section")
  fi
fi

# -- 6. Rate limits (only show if >= 50%) --
rl_parts=()
if [ -n "$rl5h" ] && [ "$rl5h" -ge 50 ] 2>/dev/null; then
  rl_parts+=("5h:${rl5h}%")
fi
if [ -n "$rl7d" ] && [ "$rl7d" -ge 50 ] 2>/dev/null; then
  rl_parts+=("7d:${rl7d}%")
fi
if [ "${#rl_parts[@]}" -gt 0 ]; then
  rl_str=$(IFS=' '; echo "${rl_parts[*]}")
  sections+=("$(printf '\033[00;31mRL %s\033[00m' "$rl_str")")
fi

# -- 7. Session cost (green, only if > $0.00) --
if [ -n "$cost" ]; then
  # Compare as float; suppress if zero or negligible
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
