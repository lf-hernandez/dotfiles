#!/bin/bash
# Blocks destructive shell commands before Claude executes them.
# Exit 2 = block the command. Exit 0 = allow.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

BLOCKED_PATTERNS=(
  "rm -rf"
  "git push --force"
  "git push -f "
  "git push -f$"
  "git reset --hard"
  "git clean -f"
  "git branch -D"
  "chmod -R 777"
  "sudo rm"
  "> /dev/sda"
  "mkfs"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "Blocked: '$pattern' is a destructive operation. Run it manually if intentional." >&2
    exit 2
  fi
done

exit 0
