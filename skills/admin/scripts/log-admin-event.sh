#!/usr/bin/env bash
# =============================================================================
# Admin Suite Event Logger - Bash version for WSL/Unix
# =============================================================================
# Usage:
#   source log-admin-event.sh
#   log_admin_event "Installed node v22"
#   log_admin_event "MCP server failed" "ERROR"
#   log_admin_event "Backup completed" "OK" "backups.log"
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Detect environment and set correct ADMIN_ROOT
_detect_admin_root() {
    if [[ -n "${ADMIN_ROOT:-}" ]]; then
        echo "$ADMIN_ROOT"
        return
    fi

    if grep -qi microsoft /proc/version 2>/dev/null; then
        # WSL - profile lives on Windows side
        local win_user
        win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        echo "/mnt/c/Users/$win_user/.admin"
    else
        # Native Linux/macOS - use home directory
        echo "${HOME}/.admin"
    fi
}

# Detect platform
_detect_platform() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

log_admin_event() {
    local message="$1"
    local level="${2:-INFO}"
    local log_file="${3:-operations.log}"

    if [[ -z "$message" ]]; then
        echo -e "${RED}[ERROR]${NC} Message is required" >&2
        return 1
    fi

    # Resolve ADMIN_ROOT
    local admin_root
    admin_root=$(_detect_admin_root)

    # Ensure logs directory exists
    local logs_dir="${admin_root}/logs"
    mkdir -p "$logs_dir"

    # Get device info
    local device_name
    device_name=$(hostname)
    local platform
    platform=$(_detect_platform)

    # Format timestamp as ISO8601
    local timestamp
    timestamp=$(date -Iseconds 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S%z")

    # Build log entry
    local log_entry="[$timestamp] [$device_name] [$platform] [$level] $message"

    # Append to log file
    local log_path="${logs_dir}/${log_file}"
    echo "$log_entry" >> "$log_path"

    # Print with color
    local color
    case "$level" in
        ERROR) color="$RED" ;;
        WARN)  color="$YELLOW" ;;
        OK)    color="$GREEN" ;;
        *)     color="$CYAN" ;;
    esac
    echo -e "${color}${log_entry}${NC}"

    return 0
}

# If script is run directly (not sourced), execute with arguments
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" && -n "${0:-}" ]]; then
    if [[ $# -ge 1 ]]; then
        log_admin_event "$@"
    else
        echo "Usage: log-admin-event.sh <message> [level] [log_file]"
        echo "  level: INFO (default), WARN, ERROR, OK"
        echo "  log_file: operations.log (default)"
        exit 1
    fi
fi
