#!/bin/bash
# Generate plugin.json for all skills
# Extracts metadata from SKILL.md frontmatter
#
# Fork-aware: loads .env for author/repo overrides per-skill.
# See .env.sample for configuration.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$(cd "$ROOT_DIR/skills" && pwd)"

# --- Fork Configuration ---
# Default author (upstream)
UPSTREAM_AUTHOR_NAME="Jeremy Dawes"
UPSTREAM_AUTHOR_EMAIL="jeremy@jezweb.net"
UPSTREAM_REPOSITORY="https://github.com/jezweb/claude-skills"

# Fork overrides (from .env)
FORK_AUTHOR_NAME=""
FORK_AUTHOR_EMAIL=""
FORK_REPOSITORY=""
FORK_SKILL_PATHS=""

if [ -f "$ROOT_DIR/.env" ]; then
  # Source .env safely (only known vars)
  FORK_AUTHOR_NAME=$(grep '^PLUGIN_AUTHOR_NAME=' "$ROOT_DIR/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
  FORK_AUTHOR_EMAIL=$(grep '^PLUGIN_AUTHOR_EMAIL=' "$ROOT_DIR/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
  FORK_REPOSITORY=$(grep '^PLUGIN_REPOSITORY=' "$ROOT_DIR/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
  FORK_SKILL_PATHS=$(grep '^SKILL_PATHS=' "$ROOT_DIR/.env" | cut -d= -f2- | tr -d '"' | tr -d "'" | tr -d ' ')
  echo "Loaded .env: author=$FORK_AUTHOR_NAME, skills=$(echo "$FORK_SKILL_PATHS" | tr ',' ' ' | wc -w) fork-owned"
fi

# Helper: check if skill is owned by fork author
is_fork_skill() {
  local skill="$1"
  if [ -z "$FORK_SKILL_PATHS" ]; then
    return 1
  fi
  echo ",$FORK_SKILL_PATHS," | grep -q ",$skill,"
}

echo "Generating plugin.json files for all skills..."
echo "Skills directory: $SKILLS_DIR"
echo ""

# Counter for tracking progress
count=0
total=$(ls -1 "$SKILLS_DIR" | wc -l)

# Iterate through all skill directories
for skill_dir in "$SKILLS_DIR"/*; do
  if [ ! -d "$skill_dir" ]; then
    continue
  fi

  skill_name=$(basename "$skill_dir")
  skill_md="$skill_dir/SKILL.md"
  plugin_dir="$skill_dir/.claude-plugin"
  plugin_json="$plugin_dir/plugin.json"

  count=$((count + 1))
  echo "[$count/$total] Processing: $skill_name"

  # Check if SKILL.md exists
  if [ ! -f "$skill_md" ]; then
    echo "  ⚠️  Warning: SKILL.md not found, skipping"
    continue
  fi

  # Create .claude-plugin directory
  mkdir -p "$plugin_dir"

  # Extract metadata from SKILL.md frontmatter
  # Look for YAML frontmatter between --- markers
  description=""
  keywords=""

  # Extract description (handle single-line, multi-line with |, and multi-line with >)
  # First try single-line format
  description=$(awk '{gsub(/\r$/,"")} /^description:/{if($0 !~ /[\|>]$/){gsub(/^description: */, ""); print; exit}}' "$skill_md")

  # If not found or empty, try multi-line format with | or >
  if [ -z "$description" ]; then
    description=$(awk '
      {gsub(/\r$/,"")}
      /^description: [\|>]/{flag=1; next}
      /^---$/{flag=0}
      /^[a-z-]+:/{flag=0}
      flag && /^  /{gsub(/^  /, ""); line=line $0 " "}
      END{gsub(/ $/, "", line); print line}
    ' "$skill_md")
  fi

  # If description is still empty or problematic, use a default
  if [ -z "$description" ] || [ "$description" = "|" ] || [ "$description" = ">" ]; then
    description="Production-ready skill for $skill_name"
  fi

  # Extract keywords BEFORE truncating description
  # Keywords are in the format "Keywords: keyword1, keyword2, ..."
  keywords_raw=$(echo "$description" | grep -oP 'Keywords:\s*\K[^$]*' | tr -d '"' | tr -d "'")

  # If no keywords found in description, try YAML format
  if [ -z "$keywords_raw" ]; then
    keywords_raw=$(awk '/^keywords:/{flag=1; next} /^[a-z-]+:/{flag=0} flag && /^  - /{gsub(/^  - /, ""); print}' "$skill_md" | tr '\n' ',' | sed 's/,$//')
  fi

  # Clean up and convert keywords to JSON array
  keywords_json="[]"
  if [ -n "$keywords_raw" ]; then
    # Split by comma, trim whitespace, limit to first 15 keywords
    keywords_json=$(echo "$keywords_raw" | sed 's/,/\n/g' | sed 's/^ *//;s/ *$//' | grep -v '^$' | head -15 | awk '
      BEGIN { printf "[" }
      {
        gsub(/\\/, "\\\\")
        gsub(/"/, "")
        if (NR > 1) printf ","
        printf "\"%s\"", $0
      }
      END { printf "]" }
    ')
  fi

  # Now clean up description (remove Keywords line, trim, limit to 500 chars)
  description=$(echo "$description" | sed 's/Keywords:.*$//' | tr -d '"' | tr -d "'" | sed 's/  */ /g' | sed 's/^ *//;s/ *$//' | head -c 500)

  # Detect agents in skill's agents/ directory (logging only)
  # NOTE: agents field is NOT emitted in plugin.json - it causes validation errors.
  # Agents are auto-discovered from the agents/ directory at plugin root.
  agents_dir="$skill_dir/agents"
  if [ -d "$agents_dir" ]; then
    agent_count=$(find "$agents_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    if [ "$agent_count" -gt 0 ]; then
      agent_names=$(find "$agents_dir" -maxdepth 1 -name "*.md" -type f -exec basename {} .md \; | sort | tr '\n' ' ')
      echo "  📦 Found $agent_count agent(s) (auto-discovered): $agent_names"
    fi
  fi

  # Detect commands in skill's commands/ directory
  # Per Claude Code plugin spec: commands field should be directory path
  commands_json=""
  commands_dir="$skill_dir/commands"
  if [ -d "$commands_dir" ]; then
    command_count=$(find "$commands_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    if [ "$command_count" -gt 0 ]; then
      commands_json="\"./commands/\""
      command_names=$(find "$commands_dir" -maxdepth 1 -name "*.md" -type f -exec basename {} .md \; | sort | tr '\n' ' ')
      echo "  📜 Found $command_count command(s): $command_names"
    fi
  fi

  # Read version: VERSION file > existing plugin.json > default 1.0.0
  version="1.0.0"
  version_file="$skill_dir/VERSION"
  if [ -f "$version_file" ]; then
    version=$(cat "$version_file" | tr -d '[:space:]')
  elif [ -f "$plugin_json" ]; then
    existing_version=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$plugin_json" 2>/dev/null || true)
    if [ -n "$existing_version" ]; then
      version="$existing_version"
    fi
  fi

  # Determine author: fork-owned skills get fork author, others get upstream
  if is_fork_skill "$skill_name" && [ -n "$FORK_AUTHOR_NAME" ]; then
    author_name="$FORK_AUTHOR_NAME"
    author_email="$FORK_AUTHOR_EMAIL"
    repo_url="${FORK_REPOSITORY:-$UPSTREAM_REPOSITORY}"
  else
    author_name="$UPSTREAM_AUTHOR_NAME"
    author_email="$UPSTREAM_AUTHOR_EMAIL"
    repo_url="$UPSTREAM_REPOSITORY"
  fi

  # Generate plugin.json
  # Build optional fields (agents excluded - causes validation errors, auto-discovered instead)
  commands_line=""
  if [ -n "$commands_json" ]; then
    commands_line=",
  \"commands\": $commands_json"
  fi

  cat > "$plugin_json" << EOF
{
  "name": "$skill_name",
  "description": "$description",
  "version": "$version",
  "author": {
    "name": "$author_name",
    "email": "$author_email"
  },
  "license": "MIT",
  "repository": "$repo_url",
  "keywords": $keywords_json$commands_line
}
EOF

  echo "  ✅ Created: $plugin_json"
done

echo ""
echo "✅ Done! Generated plugin.json for $count skills"
echo ""

# Dynamic footer based on config
repo_display="${FORK_REPOSITORY:-$UPSTREAM_REPOSITORY}"
if echo "$repo_display" | grep -q "github.com/"; then
  marketplace_name=$(echo "$repo_display" | sed 's|.*github.com/||' | sed 's|\.git$||' | tr '/' '-')
  echo "Next steps:"
  echo "1. Review generated files: find skills/ -name plugin.json"
  echo "2. Test marketplace: /plugin marketplace add $repo_display"
  echo "3. Install a skill: /plugin install <skill-name>@$marketplace_name"
else
  echo "Next steps:"
  echo "1. Review generated files: find skills/ -name plugin.json"
  echo "2. Commit and push changes"
  echo "3. Update marketplace on test machines"
fi
