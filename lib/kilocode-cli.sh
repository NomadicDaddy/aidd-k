#!/bin/bash
# =============================================================================
# lib/kilocode-cli.sh - KiloCode CLI Interaction Module for aidd-k
# =============================================================================
# Functions for interacting with KiloCode CLI, including error detection

# Source configuration and utilities
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# -----------------------------------------------------------------------------
# KiloCode CLI Interaction Functions
# -----------------------------------------------------------------------------

# Run KiloCode prompt with timeout and idle detection
# Usage: run_kilocode_prompt <project_dir> <prompt_path> [model_args...]
# Returns: Exit code from KiloCode or custom codes (70=no assistant, 71=idle timeout, 72=provider error)
run_kilocode_prompt() {
    local project_dir="$1"
    local prompt_path="$2"
    shift 2

    local -a model_args=("$@")
    local saw_no_assistant=false
    local saw_idle_timeout=false
    local saw_provider_error=false

    log_debug "Running KiloCode prompt: $prompt_path"
    log_debug "Project directory: $project_dir"
    log_debug "Model args: ${model_args[*]}"

    # Execute KiloCode in a coprocess to monitor output
    coproc KILOCODE_PROC {
        (cd "$project_dir" && cat "$prompt_path" | \
         kilocode --mode "$KILOCODE_MODE" "$KILOCODE_AUTO_FLAG" \
                   --timeout "$TIMEOUT" "$KILOCODE_NOSPLASH_FLAG" \
                   "${model_args[@]}") 2>&1;
    }

    # Monitor output for error patterns and idle timeout
    while true; do
        local line=""
        if IFS= read -r -t "$IDLE_TIMEOUT" line <&"${KILOCODE_PROC[0]}"; then
            echo "$line"
            
            # Check for "no assistant messages" pattern
            if [[ "$line" == *"$PATTERN_NO_ASSISTANT"* ]]; then
                saw_no_assistant=true
                log_error "Detected 'no assistant messages' from model; aborting."
                kill -TERM "$KILOCODE_PROC_PID" 2>/dev/null || true
                break
            fi
            
            # Check for provider error pattern
            if [[ "$line" == *"$PATTERN_PROVIDER_ERROR"* ]]; then
                saw_provider_error=true
                log_error "Detected 'provider error' from model; aborting."
                kill -TERM "$KILOCODE_PROC_PID" 2>/dev/null || true
                break
            fi
            
            continue
        fi

        # Check if process is still running (idle timeout)
        if kill -0 "$KILOCODE_PROC_PID" 2>/dev/null; then
            saw_idle_timeout=true
            log_error "Idle timeout (${IDLE_TIMEOUT}s) waiting for KiloCode output; aborting."
            kill -TERM "$KILOCODE_PROC_PID" 2>/dev/null || true
            break
        fi

        # Process has finished
        break
    done

    # Wait for process to finish and get exit code
    wait "$KILOCODE_PROC_PID" 2>/dev/null
    local exit_code=$?

    # Return custom exit codes based on detected conditions
    if [[ "$saw_no_assistant" == true ]]; then
        return $EXIT_KILOCODE_NO_ASSISTANT
    fi

    if [[ "$saw_idle_timeout" == true ]]; then
        return $EXIT_KILOCODE_IDLE_TIMEOUT
    fi

    if [[ "$saw_provider_error" == true ]]; then
        return $EXIT_KILOCODE_PROVIDER_ERROR
    fi

    return "$exit_code"
}

# Check if KiloCode is available
# Usage: check_kilocode_available
# Returns: 0 if available, 1 if not
check_kilocode_available() {
    if command_exists "$KILOCODE_CLI"; then
        log_debug "KiloCode CLI found: $KILOCODE_CLI"
        return 0
    else
        log_error "KiloCode CLI not found: $KILOCODE_CLI"
        return 1
    fi
}

# Get KiloCode version
# Usage: get_kilocode_version
# Returns: Version string or empty string if not available
get_kilocode_version() {
    if check_kilocode_available; then
        kilocode --version 2>/dev/null | head -n1
    else
        echo ""
    fi
}

# Simple KiloCode execution without monitoring
# Usage: kilocode_simple <project_dir> <prompt_path> [model_args...]
# Returns: Exit code from KiloCode
kilocode_simple() {
    local project_dir="$1"
    local prompt_path="$2"
    shift 2

    local -a model_args=("$@")

    log_debug "Simple KiloCode execution: $prompt_path"

    (cd "$project_dir" && cat "$prompt_path" | \
     kilocode --mode "$KILOCODE_MODE" "$KILOCODE_AUTO_FLAG" \
               --timeout "$TIMEOUT" "$KILOCODE_NOSPLASH_FLAG" \
               "${model_args[@]}")

    return $?
}
