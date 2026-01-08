#!/usr/bin/env bash

# =============================================================================
# aidd-k.sh - AI Development Driver: KiloCode
# =============================================================================
# This script orchestrates AI-driven development using KiloCode.
#
# Module Structure:
#   - lib/config.sh: Configuration constants and defaults
#   - lib/utils.sh: Utility functions (logging, file operations)
#   - lib/args.sh: Command-line argument parsing
#   - lib/kilocode-cli.sh: KiloCode CLI interaction functions
#   - lib/project.sh: Project initialization and management
#   - lib/iteration.sh: Iteration handling and state management
# =============================================================================

# -----------------------------------------------------------------------------
# Source Library Modules
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/args.sh"
source "${SCRIPT_DIR}/lib/kilocode-cli.sh"
source "${SCRIPT_DIR}/lib/project.sh"
source "${SCRIPT_DIR}/lib/iteration.sh"

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------
export NEW_PROJECT_CREATED=false

# -----------------------------------------------------------------------------
# ARGUMENT PARSING
# -----------------------------------------------------------------------------
init_args "$@"
if [[ $? -ne 0 ]]; then
    exit $?
fi

# -----------------------------------------------------------------------------
# INITIALIZATION
# -----------------------------------------------------------------------------

# Check if KiloCode is available
if ! check_kilocode_available; then
    log_error "KiloCode CLI is not available. Please install it first."
    exit $EXIT_GENERAL_ERROR
fi

# Print project information
log_info "Project directory: $PROJECT_DIR"

# Setup project (initialize if needed, copy artifacts, etc.)
setup_project "$PROJECT_DIR" "$SCRIPT_DIR" "$SPEC_FILE" NEW_PROJECT_CREATED

# Initialize iterations
init_iterations "$PROJECT_DIR"

# Check if spec is required (only for new projects or when metadata dir doesn't have spec.txt)
NEEDS_SPEC=false
if [[ ! -d "$PROJECT_DIR" ]] || ! is_existing_codebase "$PROJECT_DIR"; then
    NEEDS_SPEC=true
fi

if [[ "$NEEDS_SPEC" == true && -z "$SPEC_FILE" ]]; then
    log_error "Missing required argument --spec (required for new projects or when spec.txt doesn't exist)"
    log_info "Use --help for usage information"
    exit $EXIT_INVALID_ARGS
fi

# Check if spec file exists (only if provided)
if [[ -n "$SPEC_FILE" && ! -f "$SPEC_FILE" ]]; then
    log_error "Spec file '$SPEC_FILE' does not exist"
    exit $EXIT_NOT_FOUND
fi

# -----------------------------------------------------------------------------
# CLEANUP HANDLER
# -----------------------------------------------------------------------------

# Set trap to clean logs on script exit (both normal and interrupted)
trap 'cleanup_logs "$SCRIPT_DIR"' EXIT

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------

# Run the iteration cycle
run_iteration_cycle "$MAX_ITERATIONS" "$SCRIPT_DIR"

# -----------------------------------------------------------------------------
# EXIT
# -----------------------------------------------------------------------------

# Exit with success
exit $EXIT_SUCCESS
