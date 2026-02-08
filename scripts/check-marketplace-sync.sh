#!/usr/bin/env bash

# check-marketplace-sync.sh - Verify marketplace.json matches actual skills
# Usage: ./scripts/check-marketplace-sync.sh [--markdown FILE] [--fix]
#
# Checks:
# - Skills in marketplace.json that don't exist in skills/ (phantom)
# - Skills in skills/ that aren't in marketplace.json (missing)
#
# Options:
#   --markdown FILE  Append results to markdown report file
#   --fix            Automatically regenerate marketplace.json
#
# Exit codes:
#   0 - All skills in sync
#   1 - Mismatches found (unless --fix used)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MARKETPLACE_FILE="$REPO_ROOT/.claude-plugin/marketplace.json"
SKILLS_DIR="$REPO_ROOT/skills"

# Parse arguments
MARKDOWN_FILE=""
FIX_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --markdown)
            MARKDOWN_FILE="$2"
            shift 2
            ;;
        --fix)
            FIX_MODE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Temp files
MARKETPLACE_SKILLS=$(mktemp)
ACTUAL_SKILLS=$(mktemp)
trap "rm -f $MARKETPLACE_SKILLS $ACTUAL_SKILLS" EXIT

# Extract skills from marketplace.json
if [ ! -f "$MARKETPLACE_FILE" ]; then
    echo -e "${RED}ERROR: marketplace.json not found at $MARKETPLACE_FILE${NC}"
    exit 1
fi

grep -o '"./skills/[^"]*"' "$MARKETPLACE_FILE" | tr -d '"' | sed 's|./skills/||' | sort > "$MARKETPLACE_SKILLS"

# List actual skills
ls -d "$SKILLS_DIR"/*/ 2>/dev/null | sed "s|$SKILLS_DIR/||" | sed 's|/$||' | sort > "$ACTUAL_SKILLS"

# Find mismatches
PHANTOM_SKILLS=$(comm -23 "$MARKETPLACE_SKILLS" "$ACTUAL_SKILLS")
MISSING_SKILLS=$(comm -13 "$MARKETPLACE_SKILLS" "$ACTUAL_SKILLS")

MARKETPLACE_COUNT=$(wc -l < "$MARKETPLACE_SKILLS" | tr -d ' ')
ACTUAL_COUNT=$(wc -l < "$ACTUAL_SKILLS" | tr -d ' ')
PHANTOM_COUNT=$(echo "$PHANTOM_SKILLS" | grep -c . 2>/dev/null || echo 0)
PHANTOM_COUNT=$(echo "$PHANTOM_COUNT" | tr -d '[:space:]')
MISSING_COUNT=$(echo "$MISSING_SKILLS" | grep -c . 2>/dev/null || echo 0)
MISSING_COUNT=$(echo "$MISSING_COUNT" | tr -d '[:space:]')

# Print header
echo -e "${CYAN}${BOLD}Marketplace Sync Check${NC}"
echo -e "${CYAN}══════════════════════${NC}"
echo ""

# Summary
echo -e "${BOLD}Summary:${NC}"
echo "  Skills in marketplace.json: $MARKETPLACE_COUNT"
echo "  Skills in skills/ directory: $ACTUAL_COUNT"
echo ""

# Check for issues
HAS_ISSUES=false

if [ "$PHANTOM_COUNT" -gt 0 ]; then
    HAS_ISSUES=true
    echo -e "${RED}❌ $PHANTOM_COUNT skill(s) in marketplace.json but NOT in repo:${NC}"
    echo "$PHANTOM_SKILLS" | while read skill; do
        [ -n "$skill" ] && echo "   - $skill"
    done
    echo ""
fi

if [ "$MISSING_COUNT" -gt 0 ]; then
    HAS_ISSUES=true
    echo -e "${YELLOW}⚠️  $MISSING_COUNT skill(s) in repo but NOT in marketplace.json:${NC}"
    echo "$MISSING_SKILLS" | while read skill; do
        [ -n "$skill" ] && echo "   - $skill"
    done
    echo ""
fi

if [ "$HAS_ISSUES" = false ]; then
    echo -e "${GREEN}✅ All $ACTUAL_COUNT skills in sync!${NC}"
    echo ""
fi

# Write to markdown report if requested
if [ -n "$MARKDOWN_FILE" ]; then
    echo "" >> "$MARKDOWN_FILE"
    echo "## Marketplace Sync" >> "$MARKDOWN_FILE"
    echo "" >> "$MARKDOWN_FILE"
    echo "| Metric | Count |" >> "$MARKDOWN_FILE"
    echo "|--------|-------|" >> "$MARKDOWN_FILE"
    echo "| Skills in marketplace.json | $MARKETPLACE_COUNT |" >> "$MARKDOWN_FILE"
    echo "| Skills in repo | $ACTUAL_COUNT |" >> "$MARKDOWN_FILE"
    echo "| Phantom (listed but missing) | $PHANTOM_COUNT |" >> "$MARKDOWN_FILE"
    echo "| Missing (exist but not listed) | $MISSING_COUNT |" >> "$MARKDOWN_FILE"
    echo "" >> "$MARKDOWN_FILE"

    if [ "$PHANTOM_COUNT" -gt 0 ]; then
        echo "### Phantom Skills (remove from marketplace.json)" >> "$MARKDOWN_FILE"
        echo "" >> "$MARKDOWN_FILE"
        echo "$PHANTOM_SKILLS" | while read skill; do
            [ -n "$skill" ] && echo "- \`$skill\`" >> "$MARKDOWN_FILE"
        done
        echo "" >> "$MARKDOWN_FILE"
    fi

    if [ "$MISSING_COUNT" -gt 0 ]; then
        echo "### Missing Skills (add to marketplace.json)" >> "$MARKDOWN_FILE"
        echo "" >> "$MARKDOWN_FILE"
        echo "$MISSING_SKILLS" | while read skill; do
            [ -n "$skill" ] && echo "- \`$skill\`" >> "$MARKDOWN_FILE"
        done
        echo "" >> "$MARKDOWN_FILE"
    fi

    if [ "$HAS_ISSUES" = false ]; then
        echo "✅ **All skills in sync** - marketplace.json matches skills/ directory" >> "$MARKDOWN_FILE"
        echo "" >> "$MARKDOWN_FILE"
    fi
fi

# Fix mode
if [ "$FIX_MODE" = true ] && [ "$HAS_ISSUES" = true ]; then
    echo -e "${BLUE}Regenerating marketplace.json from skills/ directory...${NC}"

    # Load fork config for owner info
    OWNER_NAME="Jeremy Dawes"
    OWNER_EMAIL="jeremy@jezweb.net"
    if [ -f "$REPO_ROOT/.env" ]; then
        _name=$(grep '^PLUGIN_AUTHOR_NAME=' "$REPO_ROOT/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
        _email=$(grep '^PLUGIN_AUTHOR_EMAIL=' "$REPO_ROOT/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
        [ -n "$_name" ] && OWNER_NAME="$_name"
        [ -n "$_email" ] && OWNER_EMAIL="$_email"
    fi

    SKILL_COUNT=$(wc -l < "$ACTUAL_SKILLS" | tr -d ' ')
    TODAY=$(date +%Y-%m-%d)
    MARKETPLACE_NAME=$(basename "$REPO_ROOT")

    # Build marketplace.json
    {
        cat << HEADER
{
  "name": "$MARKETPLACE_NAME",
  "owner": {
    "name": "$OWNER_NAME",
    "email": "$OWNER_EMAIL"
  },
  "metadata": {
    "description": "Production-tested skills for Claude Code",
    "version": "1.0.0",
    "updated": "$TODAY"
  },
  "plugins": [
    {
      "name": "all",
      "description": "All $SKILL_COUNT production-tested skills for Claude Code.",
      "source": "./"
    },
HEADER

        first=true
        while IFS= read -r skill; do
            [ -z "$skill" ] && continue
            skill_md="$SKILLS_DIR/$skill/SKILL.md"
            if [ ! -f "$skill_md" ]; then
                continue
            fi

            # Extract description
            desc=$(awk '/^description:/{if($0 !~ /[\|>]$/){gsub(/^description: */, ""); print; exit}}' "$skill_md")
            if [ -z "$desc" ]; then
                desc=$(awk '/^description: [\|>]/{flag=1; next} /^[a-z-]+:/{flag=0} flag && /^  /{gsub(/^  /, ""); line=line $0 " "} END{gsub(/ $/, "", line); print line}' "$skill_md")
            fi
            [ -z "$desc" ] && desc="Production-ready skill for $skill"
            desc=$(echo "$desc" | sed 's/Keywords:.*$//' | tr -d '"' | tr -d "'" | sed 's/  */ /g' | sed 's/^ *//;s/ *$//' | head -c 200)

            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            printf '    {\n      "name": "%s",\n      "description": "%s",\n      "source": "./skills/%s"\n    }' "$skill" "$desc" "$skill"
        done < "$ACTUAL_SKILLS"

        echo ""
        echo "  ]"
        echo "}"
    } > "$MARKETPLACE_FILE"

    echo -e "${GREEN}✅ marketplace.json regenerated ($SKILL_COUNT skills)${NC}"

    # Also regenerate per-skill plugin.json files
    echo -e "${BLUE}Also regenerating per-skill plugin.json files...${NC}"
    "$SCRIPT_DIR/generate-plugin-manifests.sh"

    exit 0
fi

# Exit code
if [ "$HAS_ISSUES" = true ]; then
    echo -e "${YELLOW}Run with --fix to regenerate marketplace.json${NC}"
    echo "Or manually run: ./scripts/generate-plugin-manifests.sh"
    exit 1
fi

exit 0
