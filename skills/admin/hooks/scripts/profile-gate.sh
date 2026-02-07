#!/usr/bin/env bash
# Profile gate check - validates profile exists before admin operations.
# Receives JSON on stdin with { "prompt": "user's prompt text" }.
# Exits 0 to allow, exits 2 with JSON to block.

set -euo pipefail

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")

# Only gate on admin-relevant prompts
KEYWORDS="install|uninstall|setup|configure|mcp server|add to path|update profile|clone repo|brew |apt |winget |scoop |npm install|pip install|uv install"
if ! echo "$PROMPT" | grep -qiE "$KEYWORDS"; then
  exit 0
fi

# Check if profile exists
PROFILE_DIR="$HOME/.admin/profiles"
HOSTNAME_FILE="$PROFILE_DIR/$(hostname).json"

if [ -f "$HOSTNAME_FILE" ]; then
  exit 0
fi

# No profile found - block with message
cat <<'EOF'
{"decision":"block","reason":"No admin device profile found. Run /setup-profile to create one before running admin operations."}
EOF
exit 2
