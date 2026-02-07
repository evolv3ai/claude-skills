#!/bin/bash
# sync-skills.sh
# Sync skills across AI coding clients

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Detect environment (from admin skill)
detect_environment() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        ADMIN_ROOT="/mnt/c/Users/$WIN_USER/.admin"
        ENV_TYPE="wsl"
    elif [[ "$OS" == "Windows_NT" || -n "$MSYSTEM" ]]; then
        ADMIN_ROOT="$HOME/.admin"
        ENV_TYPE="windows-gitbash"
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        ADMIN_ROOT="$HOME/.admin"
        ENV_TYPE="macos"
    else
        ADMIN_ROOT="$HOME/.admin"
        ENV_TYPE="linux"
    fi

    HOSTNAME=$(hostname)
    PROFILE_PATH="$ADMIN_ROOT/profiles/$HOSTNAME.json"
    REGISTRY_PATH="$ADMIN_ROOT/skills-registry.json"
}

# Get registry path from profile
get_registry_path() {
    if [[ -f "$PROFILE_PATH" ]]; then
        local reg_path=$(jq -r '.paths.skillsRegistry // empty' "$PROFILE_PATH")
        if [[ -n "$reg_path" ]]; then
            # Convert Windows path if needed
            if [[ "$ENV_TYPE" == "wsl" && "$reg_path" == *":"* ]]; then
                local drive=$(echo "$reg_path" | cut -c1 | tr '[:upper:]' '[:lower:]')
                local rest=$(echo "$reg_path" | cut -c3- | sed 's|\\|/|g')
                REGISTRY_PATH="/mnt/$drive$rest"
            else
                REGISTRY_PATH="$reg_path"
            fi
        fi
    fi
}

# List installed skills
list_skills() {
    echo -e "${BLUE}Installed Skills:${NC}"
    echo ""

    if [[ ! -f "$REGISTRY_PATH" ]]; then
        echo -e "${RED}Registry not found at $REGISTRY_PATH${NC}"
        exit 1
    fi

    jq -r '.installedSkills | to_entries[] | "\(.key)\t\(.value.source)\t\(.value.status)\t\(.value.clients | join(","))"' "$REGISTRY_PATH" | \
    while IFS=$'\t' read -r name source status clients; do
        printf "${GREEN}%-25s${NC} %-30s %-10s %s\n" "$name" "$source" "$status" "$clients"
    done
}

# Sync skill to Cursor
sync_to_cursor() {
    local skill_name="$1"
    local source_path="$HOME/.claude/skills/$skill_name"
    local target_dir="$HOME/.cursor/rules"
    local target_file="$target_dir/$skill_name.md"

    if [[ ! -d "$source_path" ]]; then
        echo -e "${RED}Skill not found: $source_path${NC}"
        return 1
    fi

    mkdir -p "$target_dir"

    echo "# $skill_name (synced from Claude Code)" > "$target_file"
    echo "# Source: evolv3-ai/vibe-skills" >> "$target_file"
    echo "# Synced: $(date -Iseconds)" >> "$target_file"
    echo "" >> "$target_file"
    cat "$source_path/SKILL.md" >> "$target_file"

    echo -e "${GREEN}Synced $skill_name to Cursor: $target_file${NC}"

    # Update registry
    update_registry_client "$skill_name" "cursor"
}

# Sync skill to Windsurf
sync_to_windsurf() {
    local skill_name="$1"
    local source_path="$HOME/.claude/skills/$skill_name"
    local target_dir="$HOME/.windsurf"
    local target_file="$target_dir/$skill_name.md"

    if [[ ! -d "$source_path" ]]; then
        echo -e "${RED}Skill not found: $source_path${NC}"
        return 1
    fi

    mkdir -p "$target_dir"

    echo "# $skill_name (synced from Claude Code)" > "$target_file"
    cat "$source_path/SKILL.md" >> "$target_file"

    echo -e "${GREEN}Synced $skill_name to Windsurf: $target_file${NC}"

    update_registry_client "$skill_name" "windsurf"
}

# Update registry with new client
update_registry_client() {
    local skill_name="$1"
    local client="$2"

    if [[ ! -f "$REGISTRY_PATH" ]]; then
        return
    fi

    # Add client to skill's clients array if not present
    local updated=$(jq --arg skill "$skill_name" --arg client "$client" '
        if .installedSkills[$skill] then
            .installedSkills[$skill].clients = (.installedSkills[$skill].clients + [$client] | unique)
        else
            .
        end
    ' "$REGISTRY_PATH")

    echo "$updated" > "$REGISTRY_PATH"
}

# Show usage
usage() {
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  list                    List all installed skills"
    echo "  sync <skill> <client>   Sync skill to client (cursor, windsurf)"
    echo "  audit                   Check all skills health"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 sync admin-skills cursor"
    echo "  $0 audit"
}

# Audit skills
audit_skills() {
    echo -e "${BLUE}Skills Audit:${NC}"
    echo ""

    local skills_dir="$HOME/.claude/skills"

    jq -r '.installedSkills | keys[]' "$REGISTRY_PATH" | while read -r skill; do
        local exists="NO"
        local status=$(jq -r ".installedSkills[\"$skill\"].status" "$REGISTRY_PATH")

        if [[ -d "$skills_dir/$skill" ]]; then
            exists="YES"
        fi

        if [[ "$exists" == "YES" && "$status" == "active" ]]; then
            printf "${GREEN}%-25s${NC} Files: %-5s Status: %s\n" "$skill" "$exists" "$status"
        else
            printf "${YELLOW}%-25s${NC} Files: %-5s Status: %s\n" "$skill" "$exists" "$status"
        fi
    done
}

# Main
detect_environment
get_registry_path

case "${1:-}" in
    list)
        list_skills
        ;;
    sync)
        if [[ -z "${2:-}" || -z "${3:-}" ]]; then
            echo "Usage: $0 sync <skill-name> <client>"
            echo "Clients: cursor, windsurf"
            exit 1
        fi
        case "$3" in
            cursor)
                sync_to_cursor "$2"
                ;;
            windsurf)
                sync_to_windsurf "$2"
                ;;
            *)
                echo "Unknown client: $3"
                exit 1
                ;;
        esac
        ;;
    audit)
        audit_skills
        ;;
    *)
        usage
        ;;
esac
