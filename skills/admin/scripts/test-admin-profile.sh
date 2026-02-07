#!/usr/bin/env bash
# =============================================================================
# Test Admin Profile - Checks if admin profile exists
# =============================================================================
# Reliably checks for the admin profile, handling path resolution correctly.
# Returns JSON with profile path, existence status, and basic info if exists.
#
# Usage:
#   ./test-admin-profile.sh
#   source test-admin-profile.sh && test_admin_profile
# =============================================================================

set -eo pipefail

test_admin_profile() {
    # Resolve ADMIN_ROOT
    local admin_root
    if [[ -n "${ADMIN_ROOT:-}" ]]; then
        admin_root="$ADMIN_ROOT"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        # WSL: Use Windows user's home
        local win_user
        win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        admin_root="/mnt/c/Users/$win_user/.admin"
    else
        admin_root="${HOME}/.admin"
    fi

    # Build profile path
    local device_name
    device_name=$(hostname)
    local profile_path="${admin_root}/profiles/${device_name}.json"

    # Check existence
    local exists="false"
    local schema_version=""
    local skill_version=""
    local platform=""

    if [[ -f "$profile_path" ]]; then
        exists="true"
        if command -v jq &>/dev/null; then
            schema_version=$(jq -r '.schemaVersion // empty' "$profile_path" 2>/dev/null || true)
            skill_version=$(jq -r '.adminSkillVersion // empty' "$profile_path" 2>/dev/null || true)
            platform=$(jq -r '.device.platform // empty' "$profile_path" 2>/dev/null || true)
        fi
    fi

    # Output JSON
    cat <<JSON
{"exists":${exists},"path":"${profile_path}","device":"${device_name}","adminRoot":"${admin_root}","schemaVersion":"${schema_version}","adminSkillVersion":"${skill_version}","platform":"${platform}"}
JSON
}

# Auto-run if executed directly
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" && -n "${0:-}" ]]; then
    test_admin_profile
fi
