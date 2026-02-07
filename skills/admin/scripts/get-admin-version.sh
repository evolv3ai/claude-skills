#!/usr/bin/env bash
# =============================================================================
# Admin Version Info - Displays skill and profile version information
# =============================================================================
# Shows the current admin skill version, profile schema version, and
# profile's adminSkillVersion. Warns if versions are mismatched.
#
# Usage:
#   ./get-admin-version.sh
#   source get-admin-version.sh && get_admin_version
# =============================================================================

set -eo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)
SKILL_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
VERSION_FILE="${SKILL_ROOT}/VERSION"
CHANGELOG_FILE="${SKILL_ROOT}/CHANGELOG.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

get_admin_version() {
    # Read skill version
    local skill_version="unknown"
    if [[ -f "$VERSION_FILE" ]]; then
        skill_version=$(head -1 "$VERSION_FILE" | tr -d '[:space:]')
    fi

    # Detect ADMIN_ROOT
    local admin_root
    if [[ -n "${ADMIN_ROOT:-}" ]]; then
        admin_root="$ADMIN_ROOT"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        local win_user
        win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        admin_root="/mnt/c/Users/$win_user/.admin"
    else
        admin_root="${HOME}/.admin"
    fi

    # Read profile
    local hostname
    hostname=$(hostname)
    local profile_path="${admin_root}/profiles/${hostname}.json"
    local profile_version=""
    local profile_schema_version=""
    local profile_exists=false

    if [[ -f "$profile_path" ]]; then
        profile_exists=true
        if command -v jq &>/dev/null; then
            profile_version=$(jq -r '.adminSkillVersion // empty' "$profile_path" 2>/dev/null || true)
            profile_schema_version=$(jq -r '.schemaVersion // empty' "$profile_path" 2>/dev/null || true)
        else
            # Fallback: grep for values
            profile_version=$(grep -o '"adminSkillVersion"[[:space:]]*:[[:space:]]*"[^"]*"' "$profile_path" 2>/dev/null | cut -d'"' -f4 || true)
            profile_schema_version=$(grep -o '"schemaVersion"[[:space:]]*:[[:space:]]*"[^"]*"' "$profile_path" 2>/dev/null | cut -d'"' -f4 || true)
        fi
    fi

    # Display
    echo ""
    echo -e "${CYAN}=== Admin Version Info ===${NC}"
    echo ""
    echo -e "Skill Version:    ${GREEN}${skill_version}${NC}"
    echo -e "${GRAY}Skill Location:   ${SKILL_ROOT}${NC}"
    echo ""

    if [[ "$profile_exists" == true ]]; then
        echo -e "${GRAY}Profile Found:    ${profile_path}${NC}"
        echo -e "Schema Version:   ${GREEN}${profile_schema_version}${NC}"

        if [[ -n "$profile_version" ]]; then
            echo -n "Profile Created By: "
            if [[ "$profile_version" == "$skill_version" ]]; then
                echo -e "${GREEN}${profile_version} (current)${NC}"
            else
                echo -e "${YELLOW}${profile_version}${NC}"
                echo ""
                echo -e "${YELLOW}[WARN] Profile was created by an older skill version${NC}"
                echo -e "${YELLOW}       Consider re-running setup-interview.sh to update${NC}"
            fi
        else
            echo -e "Profile Created By: ${YELLOW}(pre-versioning)${NC}"
            echo ""
            echo -e "${YELLOW}[WARN] Profile predates versioning system${NC}"
            echo -e "${YELLOW}       Run setup-interview.sh to create a versioned profile${NC}"
        fi
    else
        echo -e "Profile:          ${YELLOW}Not found${NC}"
        echo -e "${GRAY}Expected:         ${profile_path}${NC}"
        echo ""
        echo -e "${CYAN}[INFO] Run setup-interview.sh to create a profile${NC}"
    fi

    echo ""
    echo -e "${GRAY}Changelog:        ${CHANGELOG_FILE}${NC}"
    echo ""
}

# Auto-run if executed directly
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" && -n "${0:-}" ]]; then
    get_admin_version
fi
