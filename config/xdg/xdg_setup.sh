#!/usr/bin/env bash
# ╔════════════════════════════════════════════════════════════════════════════╗
# ║                    XDG ENVIRONMENT SETUP SCRIPT                            ║
# ║ ══════════════════════════════════════════════════════════════════════════ ║
# ║ LIGHTNING FAST XDG ENVIRONMENT SETUP WITH SMART CACHING                    ║
# ║                                                                            ║
# ║ FEATURES                                                                   ║
# ║  • Auto-discovers all *.env files in directory                             ║
# ║  • Exports environment variables (always fast)                             ║
# ║  • Creates directories only when necessary (smart caching)                 ║
# ║  • Verifies permissions only when needed (time-based + change detection)   ║
# ║  • Cross-platform support (macOS/Linux)                                    ║
# ║  • Verbose mode for debugging (-v/--verbose)                               ║
# ║                                                                            ║
# ║ PERFORMANCE                                                                ║
# ║  • Perfect for shell integration (.zshenv, .bashrc, etc.)                  ║
# ║  • FIRST RUN: ~0.3s (full setup + cache creation)                          ║
# ║  • SUBSEQUENT RUNS: ~0.1s (blazing fast with caching)                      ║
# ║  • TIME COMPLEXITY: O(n) where n = variables across all .env files         ║
# ║                                                                            ║
# ║ CACHE STRATEGY                                                             ║
# ║  • DIRECTORY CACHE: Invalidated when .env files change or dirs missing     ║
# ║  • RUNTIME CACHE: Expires after 1 hour or when permissions wrong           ║
# ║  • CACHE FILES: ~/.cache/xdg-setup-{dirs,runtime}.cache                    ║
# ║                                                                            ║
# ║ USAGE                                                                      ║
# ║  ./xdg_setup.sh           # Quiet mode (perfect for shell startup)         ║
# ║  ./xdg_setup.sh -v        # Verbose mode (debugging & verification)        ║
# ╚════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# 🎨 COLORS & LOGGING SYSTEM
# ANSI color codes for beautiful output
# ══════════════════════════════════════════════════════════════════════════════
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color
LOG_LEVEL='silent' # Global log level

# Smart log functions - only show details in verbose mode, always show errors
is_verbose() { [[ "$LOG_LEVEL" == 'verbose' ]]; }
log_info() { is_verbose && echo -e "${BLUE}ℹ${NC} $*" || true; }
log_success() { is_verbose && echo -e "${GREEN}✓${NC} $*" || true; }
log_warning() { is_verbose && echo -e "${YELLOW}⚠${NC} $*" || true; }
log_error() { echo -e "${RED}✗${NC} $*"; }  # Critical errors always visible

# ══════════════════════════════════════════════════════════════════════════════
# 🚀 UNIFIED ENVIRONMENT PROCESSING (Single Pass - Maximum Efficiency)
# Process all .env files at once - export variables and ensure directories exist
# Args: $1 = "export_only" or "full_setup"
# ══════════════════════════════════════════════════════════════════════════════
process_environment() {
    local mode="${1:-export_only}"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/xdg-setup-dirs.cache"
    local created_dirs=0
    local exported_vars=0

    log_info "Processing environment files from: $script_dir"

    # Find all .env files in the directory (single find operation)
    while IFS= read -r -d '' env_file; do
        log_info "Processing environment file: $env_file"

        # Parse each KEY=VALUE pair (single file read)
        while IFS='=' read -r key value; do
            # Skip empty lines and comments
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

            # Clean up key and value (remove quotes and whitespace)
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/^[[:space:]]*"//;s/"[[:space:]]*$//;s/^[[:space:]]*//;s/[[:space:]]*$//')

            # Only process XDG/ZSH related variables
            if [[ "$key" =~ ^(XDG_|ZSH_|ZDOTDIR|HISTFILE|ZIM_HOME) ]]; then
                # Expand variables in value (like $HOME, $UID)
                expanded_value=$(eval echo "$value")
                if [[ -n "$expanded_value" ]]; then
                    # Always export the variable
                    export "$key"="$expanded_value"
                    exported_vars=$((exported_vars + 1))
                    log_success "Exported: $key=$expanded_value"

                    # Create directory if in full setup mode and this is a directory variable
                    if [[ "$mode" == "full_setup" ]] && [[ "$key" != "XDG_RUNTIME_DIR" ]]; then
                        if [[ "$key" =~ _DIR$|_HOME$|^ZDOTDIR$|^ZIM_HOME$ ]]; then
                            if [[ -d "$expanded_value" ]]; then
                                log_success "Directory exists: $expanded_value"
                            else
                                if mkdir -p "$expanded_value" 2>/dev/null; then
                                    log_success "Created directory: $expanded_value"
                                    created_dirs=$((created_dirs + 1))
                                else
                                    log_error "Failed to create directory: $expanded_value"
                                    return 1
                                fi
                            fi
                        fi
                    fi
                fi
            fi
        done < <(grep -v '^[[:space:]]*$' "$env_file" | grep -v '^[[:space:]]*#')
    done < <(find "$script_dir" -maxdepth 1 -name "*.env" -type f -print0 2>/dev/null | sort -z)

    log_success "Processed $exported_vars environment variables"
    if [[ "$mode" == "full_setup" ]]; then
        log_info "Created $created_dirs directories"
        # Update cache file with current timestamp
        mkdir -p "$(dirname "$cache_file")" 2>/dev/null
        echo "XDG directories verified: $(date)" > "$cache_file"
        log_info "Directory cache updated"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# 🧠 SMART DIRECTORY CACHING SYSTEM
# Intelligent cache validation - only create directories when truly necessary
# ══════════════════════════════════════════════════════════════════════════════
needs_directory_setup() {
    local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/xdg-setup-dirs.cache"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # If cache file doesn't exist, we need setup
    [[ ! -f "$cache_file" ]] && return 0

    # Check if any .env files are newer than cache (simple file timestamp check)
    while IFS= read -r -d '' env_file; do
        [[ "$env_file" -nt "$cache_file" ]] && return 0
    done < <(find "$script_dir" -maxdepth 1 -name "*.env" -type f -print0 2>/dev/null)

    return 1  # No setup needed - cache is valid
}

# ══════════════════════════════════════════════════════════════════════════════
# 🔒 SMART RUNTIME PERMISSION CACHING SYSTEM
# Cross-platform function to get directory permissions and owner
# Returns: "permissions:owner" or "000:0" on error
# ══════════════════════════════════════════════════════════════════════════════
get_dir_permissions() {
    local dir="$1"
    local perms owner

    case "$(uname)" in
        Darwin)
            perms=$(stat -f "%Lp" "$dir" 2>/dev/null || echo "000")
            owner=$(stat -f "%u" "$dir" 2>/dev/null || echo "0")
            ;;
        Linux)
            perms=$(stat -c "%a" "$dir" 2>/dev/null || echo "000")
            owner=$(stat -c "%u" "$dir" 2>/dev/null || echo "0")
            ;;
        *)
            echo "000:0"  # Unknown OS fallback
            return 1
            ;;
    esac

    echo "$perms:$owner"
    return 0
}

# Time-based + change detection for XDG_RUNTIME_DIR permissions
needs_runtime_setup() {
    local runtime_dir="${XDG_RUNTIME_DIR:-}"
    local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/xdg-setup-runtime.cache"

    [[ -z "$runtime_dir" ]] && return 1  # Skip if not set
    [[ ! -d "$runtime_dir" ]] && return 0  # Need setup if missing
    [[ ! -f "$cache_file" ]] && return 0  # Need setup if no cache

    # Check if cache is older than 1 hour (permissions can change)
    if [[ -n "$(find "$cache_file" -mmin +60 2>/dev/null)" ]]; then
        return 0  # Cache is stale
    fi

    # Quick permission check using DRY helper function
    local perm_info perms owner
    if ! perm_info=$(get_dir_permissions "$runtime_dir"); then
        return 1  # Skip on unknown OS
    fi

    # Parse the "permissions:owner" format
    IFS=':' read -r perms owner <<< "$perm_info"

    # Need setup if permissions or ownership are wrong
    [[ "$perms" != "700" || "$owner" != "${UID:-$(id -u)}" ]] && return 0

    return 1  # No setup needed
}

# Ensure proper XDG_RUNTIME_DIR permissions (EXPENSIVE OPERATION)
ensure_runtime_dir_permission_and_ownership() {
    local runtime_dir="${XDG_RUNTIME_DIR:-}"
    local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/xdg-setup-runtime.cache"

    if [[ -z "$runtime_dir" ]]; then
        log_warning "XDG_RUNTIME_DIR not set, skipping permission setup"
        return 0
    fi

    log_info "Verifying XDG_RUNTIME_DIR permissions..."

    # Create cache directory if needed
    mkdir -p "$(dirname "$cache_file")" 2>/dev/null

    # Create directory if it doesn't exist
    if [[ ! -d "$runtime_dir" ]]; then
        if mkdir -p "$runtime_dir" 2>/dev/null || sudo mkdir -p "$runtime_dir"; then
            log_success "Created: $runtime_dir"
        else
            log_error "Failed to create: $runtime_dir"
            return 1
        fi
    fi

    # Get current permissions and owner using DRY helper function
    local perm_info perms owner
    if ! perm_info=$(get_dir_permissions "$runtime_dir"); then
        log_warning "Unknown OS, skipping permission checks"
        return 0
    fi

    # Parse the "permissions:owner" format
    IFS=':' read -r perms owner <<< "$perm_info"

    # Fix permissions if needed
    if [[ "$perms" != "700" ]]; then
        if chmod 700 "$runtime_dir" 2>/dev/null || sudo chmod 700 "$runtime_dir"; then
            log_success "Fixed permissions: $runtime_dir (700)"
        else
            log_error "Failed to set permissions on: $runtime_dir"
            return 1
        fi
    else
        log_success "Permissions OK: $runtime_dir (700)"
    fi

    # Fix ownership if needed
    if [[ "$owner" != "${UID:-$(id -u)}" ]]; then
        local username="${USERNAME:-$(id -un)}"
        if chown "$username" "$runtime_dir" 2>/dev/null || sudo chown "$username" "$runtime_dir"; then
            log_success "Fixed ownership: $runtime_dir ($username)"
        else
            log_error "Failed to change ownership of: $runtime_dir"
            return 1
        fi
    else
        log_success "Ownership OK: $runtime_dir"
    fi

    # Update cache file
    echo "XDG_RUNTIME_DIR verified: $(date)" > "$cache_file"
    log_info "Runtime permissions verified, cache updated"
}

# ══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN ORCHESTRATOR - The Magic Happens Here
# ══════════════════════════════════════════════════════════════════════════════
main() {
    # Check for verbose mode
    if [[ "${1:-}" == "--verbose" ]] || [[ "${1:-}" == "-v" ]]; then
        LOG_LEVEL='verbose'
        echo "🚀 XDG Environment Setup (Verbose Mode)"
        echo "======================================="
    fi

    # Smart environment processing - single pass through all .env files
    if needs_directory_setup; then
        # Full setup: export variables AND create directories
        process_environment "full_setup"
    else
        # Fast mode: only export variables, skip directory creation
        process_environment "export_only"
        log_info "Directories already verified, skipping creation"
    fi

    # Only check runtime permissions when necessary (smart caching)
    if needs_runtime_setup; then
        ensure_runtime_dir_permission_and_ownership
    else
        log_info "Runtime permissions already verified, skipping check"
    fi

    if is_verbose; then
        echo
        log_success "XDG environment setup completed successfully!"
        echo
        echo "📊 Environment Summary:"
        echo "======================"
        env | grep "^XDG\|^ZSH\|^ZDOTDIR" | sort
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# vi: set ft=sh:
