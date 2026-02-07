#!/usr/bin/env bash
# Deployment confirmation - flags destructive infrastructure operations.
# Receives JSON on stdin with { "tool_name": "Bash", "tool_input": { "command": "..." } }.
# Exits 0 to allow, exits 2 with JSON to block.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

# Check for destructive infrastructure keywords
DESTRUCTIVE="delete|destroy|terminate|remove server|cleanup-compartment|server delete|droplet delete|linodes delete|instance delete|force-stop|purge"
if ! echo "$COMMAND" | grep -qiE "$DESTRUCTIVE"; then
  exit 0
fi

# Destructive command detected - block and require confirmation
cat <<EOF
{"decision":"block","reason":"Destructive infrastructure operation detected: this command may permanently delete server resources. Please confirm with the user before proceeding."}
EOF
exit 2
