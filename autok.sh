#!/usr/bin/env bash

# Default values
MODEL=""
SPEC_FILE=""
MAX_ITERATIONS=""  # Empty means unlimited
PROJECT_DIR=""
TIMEOUT="600"  # Default to 600 seconds

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
            echo "  --timeout          Timeout in seconds (optional, default: 600)"
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

# Get absolute path to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check required arguments
if [[ -z "$PROJECT_DIR" || -z "$SPEC_FILE" ]]; then
    echo "Error: Missing required arguments"
    echo "Use --help for usage information"
    exit 1
fi

# Ensure project directory exists (create if missing)
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "Project directory '$PROJECT_DIR' does not exist; creating it..."
    mkdir -p "$PROJECT_DIR"

    # Copy scaffolding files to the new project directory (including hidden files)
    echo "Copying scaffolding files to '$PROJECT_DIR'..."
    # Copy both regular and hidden files
    find "$SCRIPT_DIR/scaffolding" -mindepth 1 -maxdepth 1 -exec cp -r {} "$PROJECT_DIR/" \;
fi

# Check if spec file exists
if [[ ! -f "$SPEC_FILE" ]]; then
    echo "Error: Spec file '$SPEC_FILE' does not exist"
    exit 1
fi

# Define the paths to check
SPEC_CHECK_PATH="$PROJECT_DIR/.autok/spec.txt"
FEATURE_LIST_CHECK_PATH="$PROJECT_DIR/.autok/feature_list.json"

# Iteration transcript logs
ITERATIONS_DIR="$PROJECT_DIR/.autok/iterations"
mkdir -p "$ITERATIONS_DIR"

get_next_log_index() {
    local max=0
    local f base num

    shopt -s nullglob
    for f in "$ITERATIONS_DIR"/*.log; do
        base="$(basename "${f%.log}")"
        if [[ "$base" =~ ^[0-9]+$ ]]; then
            num=$((10#$base))
            if (( num > max )); then
                max=$num
            fi
        fi
    done
    shopt -u nullglob

    echo $((max + 1))
}

NEXT_LOG_INDEX="$(get_next_log_index)"

echo "Project directory: $PROJECT_DIR"

# Check for project_dir/.autok/spec.txt
if [[ -z "$MAX_ITERATIONS" ]]; then
    echo "Running unlimited iterations (use Ctrl+C to stop)"
    i=1
    while true; do
        printf -v LOG_FILE "%s/%03d.log" "$ITERATIONS_DIR" "$NEXT_LOG_INDEX"
        NEXT_LOG_INDEX=$((NEXT_LOG_INDEX + 1))

        {
            echo "Iteration $i"
            echo "Transcript: $LOG_FILE"
            echo "Started: $(date -Is 2>/dev/null || date)"
            echo

            if [[ ! -f "$SPEC_CHECK_PATH" || ! -f "$FEATURE_LIST_CHECK_PATH" ]]; then
                echo "Required files not found, copying spec and sending initializer prompt..."
                # Create .autok directory if it doesn't exist
                mkdir -p "$PROJECT_DIR/.autok"
                # Copy spec file to project directory
                cp "$SPEC_FILE" "$SPEC_CHECK_PATH"
                # Send initializer prompt from project directory
                (cd "$PROJECT_DIR" && cat "$SCRIPT_DIR/prompts/initializer.md" | kilocode --mode code --auto --timeout "$TIMEOUT" --nosplash)
            else
                echo "Required files found, sending coding prompt..."
                # Send coding prompt from project directory
                (cd "$PROJECT_DIR" && cat "$SCRIPT_DIR/prompts/coding.md" | kilocode --mode code --auto --timeout "$TIMEOUT" --nosplash)
            fi

            echo
            echo "--- End of iteration $i ---"
            echo "Finished: $(date -Is 2>/dev/null || date)"
            echo
        } 2>&1 | tee "$LOG_FILE"

        ((i++))
    done
else
    echo "Running $MAX_ITERATIONS iterations"
    for ((i=1; i<=MAX_ITERATIONS; i++)); do
        printf -v LOG_FILE "%s/%03d.log" "$ITERATIONS_DIR" "$NEXT_LOG_INDEX"
        NEXT_LOG_INDEX=$((NEXT_LOG_INDEX + 1))

        {
            echo "Iteration $i of $MAX_ITERATIONS"
            echo "Transcript: $LOG_FILE"
            echo "Started: $(date -Is 2>/dev/null || date)"
            echo

            if [[ ! -f "$SPEC_CHECK_PATH" || ! -f "$FEATURE_LIST_CHECK_PATH" ]]; then
                echo "Required files not found, copying spec and sending initializer prompt..."
                # Create .autok directory if it doesn't exist
                mkdir -p "$PROJECT_DIR/.autok"
                # Copy spec file to project directory
                cp "$SPEC_FILE" "$SPEC_CHECK_PATH"
                # Send initializer prompt from project directory
                (cd "$PROJECT_DIR" && cat "$SCRIPT_DIR/prompts/initializer.md" | kilocode --mode code --auto --timeout "$TIMEOUT" --nosplash)
            else
                echo "Required files found, sending coding prompt..."
                # Send coding prompt from project directory
                (cd "$PROJECT_DIR" && cat "$SCRIPT_DIR/prompts/coding.md" | kilocode --mode code --auto --timeout "$TIMEOUT" --nosplash)
            fi

            # If this is not the last iteration, add a separator
            if [[ $i -lt $MAX_ITERATIONS ]]; then
                echo
                echo "--- End of iteration $i ---"
                echo "Finished: $(date -Is 2>/dev/null || date)"
                echo
            else
                echo
                echo "Finished: $(date -Is 2>/dev/null || date)"
                echo
            fi
        } 2>&1 | tee "$LOG_FILE"
    done
fi
