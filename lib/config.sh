#!/bin/bash
# =============================================================================
# lib/config.sh - Configuration Constants and Defaults for aidd-k
# =============================================================================
# Exit codes, default values, and pattern constants for error detection

# -----------------------------------------------------------------------------
# Exit Codes
# -----------------------------------------------------------------------------
: "${EXIT_SUCCESS:=0}"              # Successful execution
: "${EXIT_GENERAL_ERROR:=1}"        # General/unspecified error
: "${EXIT_INVALID_ARGS:=2}"         # Invalid command-line arguments
: "${EXIT_KILOCODE_NO_ASSISTANT:=70}"  # KiloCode returned no assistant messages
: "${EXIT_KILOCODE_IDLE_TIMEOUT:=71}"  # KiloCode idle timeout
: "${EXIT_KILOCODE_PROVIDER_ERROR:=72}"  # KiloCode provider error
: "${EXIT_SIGNAL:=124}"             # Terminated by signal (SIGINT/SIGTERM)

readonly EXIT_SUCCESS
readonly EXIT_GENERAL_ERROR
readonly EXIT_INVALID_ARGS
readonly EXIT_KILOCODE_NO_ASSISTANT
readonly EXIT_KILOCODE_IDLE_TIMEOUT
readonly EXIT_KILOCODE_PROVIDER_ERROR
readonly EXIT_SIGNAL

# -----------------------------------------------------------------------------
# Default Values
# -----------------------------------------------------------------------------
: "${DEFAULT_TIMEOUT:=600}"         # Default timeout in seconds (10 minutes)
: "${DEFAULT_IDLE_TIMEOUT:=180}"    # Default idle timeout in seconds (3 minutes)
: "${DEFAULT_NO_CLEAN:=false}"      # Default: clean up artifacts
: "${DEFAULT_QUIT_ON_ABORT:=0}"     # Default: continue on abort indefinitely

readonly DEFAULT_TIMEOUT
readonly DEFAULT_IDLE_TIMEOUT
readonly DEFAULT_NO_CLEAN
readonly DEFAULT_QUIT_ON_ABORT

# -----------------------------------------------------------------------------
# Pattern Constants for Error Detection
# -----------------------------------------------------------------------------
# Regex patterns for detecting common error conditions in KiloCode output

# KiloCode-specific error patterns
: "${PATTERN_NO_ASSISTANT:="The model returned no assistant messages"}"
: "${PATTERN_PROVIDER_ERROR:="Provider returned error"}"

readonly PATTERN_NO_ASSISTANT
readonly PATTERN_PROVIDER_ERROR

# General error patterns
: "${PATTERN_GENERAL_ERROR:="ERROR|error:|Error"}"
: "${PATTERN_WARNING:="WARNING|Warning|warning:"}"

readonly PATTERN_GENERAL_ERROR
readonly PATTERN_WARNING

# -----------------------------------------------------------------------------
# KiloCode CLI Configuration
# -----------------------------------------------------------------------------
: "${KILOCODE_CLI:="kilocode"}"    # KiloCode CLI command
: "${KILOCODE_MODE:="code"}"       # Default mode for KiloCode
: "${KILOCODE_AUTO_FLAG:="--auto"}"  # Auto mode flag
: "${KILOCODE_NOSPLASH_FLAG:="--nosplash"}"  # No splash screen flag

readonly KILOCODE_CLI
readonly KILOCODE_MODE
readonly KILOCODE_AUTO_FLAG
readonly KILOCODE_NOSPLASH_FLAG

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
: "${METADATA_DIR_NAME:=".aidd"}"        # Metadata directory name
: "${LEGACY_METADATA_DIR_AUTOK:=".autok"}"  # Legacy metadata directory (autok)
: "${LEGACY_METADATA_DIR_AUTOMAKER:=".automaker"}"  # Legacy metadata directory (automaker)
: "${ITERATIONS_DIR_NAME:="iterations"}"  # Iterations logs directory name

readonly METADATA_DIR_NAME
readonly LEGACY_METADATA_DIR_AUTOK
readonly LEGACY_METADATA_DIR_AUTOMAKER
readonly ITERATIONS_DIR_NAME

# -----------------------------------------------------------------------------
# File Patterns
# -----------------------------------------------------------------------------
: "${SPEC_FILE_NAME:="spec.txt"}"   # Specification file name
: "${FEATURE_LIST_FILE:="feature_list.json"}"  # Feature list file name

readonly SPEC_FILE_NAME
readonly FEATURE_LIST_FILE

# -----------------------------------------------------------------------------
# Template Markers
# -----------------------------------------------------------------------------
: "${TEMPLATE_DATE_MARKER:="{yyyy-mm-dd}"}"
: "${TEMPLATE_FEATURE_MARKER:="{Short name of the feature}"}"

readonly TEMPLATE_DATE_MARKER
readonly TEMPLATE_FEATURE_MARKER
