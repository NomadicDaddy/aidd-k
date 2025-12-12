#!/usr/bin/env bash

# Default values
MODEL=""
SPEC_FILE=""
MAX_ITERATIONS=""  # Empty means unlimited
PROJECT_DIR=""
TIMEOUT="6000"  # Default to 6000 seconds

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            MODEL="$2"
            shift 2
            ;;
        --spec)
            SPEC_FILE="$2"
            shift 2
            ;;
        --max-iterations)
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        --project-dir)
            PROJECT_DIR="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 --project-dir <dir> --spec <file> [--max-iterations <num>] [--timeout <seconds>] [--model <model>]"
            echo ""
            echo "Options:"
            echo "  --project-dir      Project directory (required)"
            echo "  --spec             Specification file (required)"
            echo "  --max-iterations   Maximum iterations (optional, unlimited if not specified)"
            echo "  --timeout          Timeout in seconds (optional, default: 6000)"
            echo "  --model            Model to use (optional)"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check required arguments
if [[ -z "$PROJECT_DIR" || -z "$SPEC_FILE" ]]; then
    echo "Error: Missing required arguments"
    echo "Use --help for usage information"
    exit 1
fi

# Check if project directory exists
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "Error: Project directory '$PROJECT_DIR' does not exist"
    exit 1
fi

# Check if spec file exists
if [[ ! -f "$SPEC_FILE" ]]; then
    echo "Error: Spec file '$SPEC_FILE' does not exist"
    exit 1
fi

# Get absolute path to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define the paths to check
SPEC_CHECK_PATH="$PROJECT_DIR/.autok/spec.txt"
FEATURE_LIST_CHECK_PATH="$PROJECT_DIR/.autok/feature_list.json"

# Check for project_dir/.autok/spec.txt
if [[ -z "$MAX_ITERATIONS" ]]; then
    echo "Running unlimited iterations (use Ctrl+C to stop)"
    i=1
    while true; do
        echo "Iteration $i"

        if [[ ! -f "$SPEC_CHECK_PATH" || ! -f "$FEATURE_LIST_CHECK_PATH" ]]; then
            echo "Required files not found, copying spec and sending initializer prompt..."
            # Create .autok directory if it doesn't exist
            mkdir -p "$PROJECT_DIR/.autok"
            # Copy spec file to project directory
            cp "$SPEC_FILE" "$SPEC_CHECK_PATH"
            # Send initializer prompt from project directory
            (cd "$PROJECT_DIR" && cat "$SCRIPT_DIR/prompts/initializer.md" | kilocode --auto --timeout "$TIMEOUT")
        else
            echo "Required files found, sending coding prompt..."
            # Send coding prompt from project directory
            (cd "$PROJECT_DIR" && cat "$SCRIPT_DIR/prompts/coding.md" | kilocode --auto --timeout "$TIMEOUT")
        fi

        echo "--- End of iteration $i ---"
        echo
        ((i++))
    done
else
    echo "Running $MAX_ITERATIONS iterations"
    for ((i=1; i<=MAX_ITERATIONS; i++)); do
        echo "Iteration $i of $MAX_ITERATIONS"

        if [[ ! -f "$SPEC_CHECK_PATH" || ! -f "$FEATURE_LIST_CHECK_PATH" ]]; then
            echo "Required files not found, copying spec and sending initializer prompt..."
            # Create .autok directory if it doesn't exist
            mkdir -p "$PROJECT_DIR/.autok"
            # Copy spec file to project directory
            cp "$SPEC_FILE" "$SPEC_CHECK_PATH"
            # Send initializer prompt from project directory
            (cd "$PROJECT_DIR" && cat "$SCRIPT_DIR/prompts/initializer.md" | kilocode --auto --timeout "$TIMEOUT")
        else
            echo "Required files found, sending coding prompt..."
            # Send coding prompt from project directory
            (cd "$PROJECT_DIR" && cat "$SCRIPT_DIR/prompts/coding.md" | kilocode --auto --timeout "$TIMEOUT")
        fi

        # If this is not the last iteration, add a separator
        if [[ $i -lt $MAX_ITERATIONS ]]; then
            echo "--- End of iteration $i ---"
            echo
        fi
    done
fi
