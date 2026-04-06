#!/bin/sh
# Claude Code status line - inspired by Powerlevel10k lean prompt
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name // ""')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Session info: prefer human-readable name, fall back to short ID
session_name=$(echo "$input" | jq -r '.session_name // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')
if [ -n "$session_name" ]; then
  session_label="$session_name"
elif [ -n "$session_id" ]; then
  # Show only first 8 chars of ID to keep it compact
  session_label=$(echo "$session_id" | cut -c1-8)
else
  session_label=""
fi

# Task info: active and completed counts (fields may not always be present)
tasks_active=$(echo "$input" | jq -r '.tasks.active // empty' 2>/dev/null)
tasks_completed=$(echo "$input" | jq -r '.tasks.completed // empty' 2>/dev/null)
# Fallback: try array-style counts
if [ -z "$tasks_active" ]; then
  tasks_active=$(echo "$input" | jq -r 'if .tasks then (.tasks | map(select(.status == "active" or .status == "in_progress")) | length) else empty end' 2>/dev/null)
fi
if [ -z "$tasks_completed" ]; then
  tasks_completed=$(echo "$input" | jq -r 'if .tasks then (.tasks | map(select(.status == "completed" or .status == "done")) | length) else empty end' 2>/dev/null)
fi

# Skills, MCP servers, and plugins
mcp_count=$(echo "$input" | jq -r 'if .mcp_servers then (.mcp_servers | length) else empty end' 2>/dev/null)
skills_count=$(echo "$input" | jq -r 'if .skills then (.skills | length) else empty end' 2>/dev/null)
plugins_count=$(echo "$input" | jq -r 'if .plugins then (.plugins | length) else empty end' 2>/dev/null)

# Shorten home directory to ~
home="$HOME"
short_cwd=$(echo "$cwd" | sed "s|^$home|~|")

# Git branch (skip optional lock to avoid blocking)
branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
fi

# Build status line

# user@hostname and directory
printf "\033[34m$(whoami)@$(hostname -s)\033[0m"
printf " \033[33m%s\033[0m" "$short_cwd"

# Git branch
if [ -n "$branch" ]; then
  printf " \033[32m(%s)\033[0m" "$branch"
fi

# Session label
if [ -n "$session_label" ]; then
  printf " \033[90msession:%s\033[0m" "$session_label"
fi

# Model
if [ -n "$model" ]; then
  printf " \033[36m[%s]\033[0m" "$model"
fi

# Context remaining
if [ -n "$remaining" ]; then
  printf " \033[35mctx:%s%%\033[0m" "$(printf '%.0f' "$remaining")"
fi

# Tasks: show active/completed when any task data is present
if [ -n "$tasks_active" ] || [ -n "$tasks_completed" ]; then
  active_val="${tasks_active:-0}"
  completed_val="${tasks_completed:-0}"
  printf " \033[33mtasks:%s/%s\033[0m" "$active_val" "$completed_val"
fi

# MCP servers
if [ -n "$mcp_count" ] && [ "$mcp_count" -gt 0 ] 2>/dev/null; then
  printf " \033[90mmcp:%s\033[0m" "$mcp_count"
fi

# Skills
if [ -n "$skills_count" ] && [ "$skills_count" -gt 0 ] 2>/dev/null; then
  printf " \033[90mskills:%s\033[0m" "$skills_count"
fi

# Plugins
if [ -n "$plugins_count" ] && [ "$plugins_count" -gt 0 ] 2>/dev/null; then
  printf " \033[90mplugins:%s\033[0m" "$plugins_count"
fi
