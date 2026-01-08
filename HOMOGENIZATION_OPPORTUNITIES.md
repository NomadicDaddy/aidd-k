# Homogenization Opportunities Between aidd-o and aidd-k

## Overview
This document identifies opportunities to standardize naming conventions, patterns, and structures between `aidd-o` and `aidd-k` to improve consistency across the AIDD suite.

## Current Differences

### 1. Iteration State Variables

#### aidd-o
```bash
export CURRENT_ITERATION=0
export TOTAL_ITERATIONS="${MAX_ITERATIONS:-10}"
export ITERATION_STATUS="idle"
export ITERATION_START_TIME=""
export ITERATION_END_TIME=""
export ONBOARDING_COMPLETE=false
export NEW_PROJECT_CREATED=false
export CONSECUTIVE_FAILURES=0
```

#### aidd-k
```bash
export ITERATION_NUMBER=0
export CONSECUTIVE_FAILURES=0
export NEXT_LOG_INDEX=0
export ITERATIONS_DIR=""
export METADATA_DIR=""
export SPEC_CHECK_PATH=""
export FEATURE_LIST_CHECK_PATH=""
```

**Recommendation**: Standardize to use `CURRENT_ITERATION`, `TOTAL_ITERATIONS`, `ITERATION_STATUS`, `ITERATION_START_TIME`, `ITERATION_END_TIME` across both scripts.

---

### 2. Iteration Phase Constants

#### aidd-o
```bash
readonly PHASE_INIT="init"
readonly PHASE_PLAN="plan"
readonly PHASE_CODE="code"
readonly PHASE_REVIEW="review"
readonly PHASE_VALIDATE="validate"
readonly PHASE_COMPLETE="complete"
```

#### aidd-k
```bash
readonly PHASE_ONBOARDING="onboarding"
readonly PHASE_INITIALIZER="initializer"
readonly PHASE_CODING="coding"
```

**Recommendation**: 
- aidd-o's multi-phase approach (init → plan → code → review → validate) is more comprehensive
- aidd-k's three-phase approach (onboarding → initializer → coding) is simpler and more appropriate for KiloCode
- **Keep current aidd-k approach** as it's better suited for KiloCode's workflow

---

### 3. Iteration State Constants

#### aidd-o
```bash
readonly STATE_IDLE="idle"
readonly STATE_RUNNING="running"
readonly STATE_PAUSED="paused"
readonly STATE_COMPLETED="completed"
readonly STATE_FAILED="failed"
readonly STATE_ABORTED="aborted"
```

#### aidd-k
```bash
readonly STATE_NEW="new"
readonly STATE_IN_PROGRESS="in_progress"
readonly STATE_COMPLETE="complete"
readonly STATE_FAILED="failed"
```

**Recommendation**: Standardize to use `STATE_IDLE`, `STATE_RUNNING`, `STATE_PAUSED`, `STATE_COMPLETED`, `STATE_FAILED`, `STATE_ABORTED` across both scripts.

---

### 4. CLI Interaction Patterns

#### aidd-o (OpenCode)
```bash
readonly OPENCODE_CMD="opencode run"
readonly NO_ASSISTANT_PATTERN="The model returned no assistant messages"
readonly PROVIDER_ERROR_PATTERN="Provider returned error"
readonly EXIT_NO_ASSISTANT=70
readonly EXIT_IDLE_TIMEOUT=71
readonly EXIT_PROVIDER_ERROR=72
readonly EXIT_SIGNAL_TERMINATED=124
```

#### aidd-k (KiloCode)
```bash
readonly KILOCODE_CLI="kilocode"
readonly PATTERN_NO_ASSISTANT="The model returned no assistant messages"
readonly PATTERN_PROVIDER_ERROR="Provider returned error"
readonly EXIT_KILOCODE_NO_ASSISTANT=70
readonly EXIT_KILOCODE_IDLE_TIMEOUT=71
readonly EXIT_KILOCODE_PROVIDER_ERROR=72
readonly EXIT_SIGNAL=124
```

**Recommendation**: 
- Keep CLI-specific constants separate (they're already well-named)
- Consider creating a shared `lib/cli.sh` module with generic CLI patterns

---

### 5. Iteration Flow

#### aidd-o (Multi-Phase)
```
init → plan → code → review → validate
```

#### aidd-k (Three-Phase)
```
onboarding → initializer → coding
```

**Recommendation**: 
- **Keep current approaches** - they're optimized for their respective CLIs
- aidd-o's multi-phase flow is appropriate for OpenCode's planning-heavy workflow
- aidd-k's three-phase flow is appropriate for KiloCode's coding-focused workflow

---

### 6. State Management Functions

#### Common Functions (Both Scripts)
- `save_iteration_state()` - Save iteration state to file
- `load_iteration_state()` - Load iteration state from file
- `reset_iteration_state()` - Reset iteration state

**Recommendation**: 
- Already well-standardized
- Consider adding `export_iteration_state()` function for better encapsulation

---

### 7. Project Detection

#### aidd-o
```bash
is_existing_codebase() {
    # Checks for .autoo/.automaker directories
}
```

#### aidd-k
```bash
is_existing_codebase() {
    # Checks for .autok/.automaker directories
}
```

**Recommendation**: 
- Already appropriate for each CLI's legacy directories
- Keep as-is

---

### 8. Metadata Directory Handling

#### aidd-o
```bash
find_or_create_metadata_dir() {
    # Migrates .autoo/.automaker to .aidd
}
```

#### aidd-k
```bash
find_or_create_metadata_dir() {
    # Migrates .autok/.automaker to .aidd
}
```

**Recommendation**: 
- Already standardized on `.aidd` directory name
- Keep legacy directory checks as-is (they're CLI-specific)

---

### 9. Logging Patterns

#### aidd-o
```bash
log_debug() { log $LOG_DEBUG "$@"; }
log_info() { log $LOG_INFO "$@"; }
log_warn() { log $LOG_WARN "$@"; }
log_error() { log $LOG_ERROR "$@"; }
```

#### aidd-k
```bash
log_debug() { log $LOG_DEBUG "$@"; }
log_info() { log $LOG_INFO "$@"; }
log_warn() { log $LOG_WARN "$@"; }
log_error() { log $LOG_ERROR "$@"; }
```

**Recommendation**: 
- Already well-standardized
- Both use the same pattern

---

### 10. Error Handling

#### aidd-o
```bash
handle_failure() {
    local exit_code="$1"
    # Check for signal termination (124)
    # Increment failure counter
    # Check quit threshold
}
```

#### aidd-k
```bash
handle_failure() {
    local exit_code="$1"
    # Increment failure counter
    # Check quit threshold
}
```

**Recommendation**: 
- Already well-standardized
- Both use the same pattern

---

### 11. Exit Code Constants

#### aidd-o
```bash
readonly EXIT_SUCCESS=0
readonly EXIT_GENERAL_ERROR=1
readonly EXIT_INVALID_ARGS=2
readonly EXIT_NOT_FOUND=3
readonly EXIT_PERMISSION_DENIED=4
readonly EXIT_TIMEOUT=5
readonly EXIT_ABORTED=6
readonly EXIT_VALIDATION_ERROR=7
readonly EXIT_OPENCODE_ERROR=8
readonly EXIT_NO_ASSISTANT=70
readonly EXIT_IDLE_TIMEOUT=71
readonly EXIT_PROVIDER_ERROR=72
readonly EXIT_SIGNAL_TERMINATED=124
```

#### aidd-k
```bash
readonly EXIT_SUCCESS=0
readonly EXIT_GENERAL_ERROR=1
readonly EXIT_INVALID_ARGS=2
readonly EXIT_KILOCODE_NO_ASSISTANT=70
readonly EXIT_KILOCODE_IDLE_TIMEOUT=71
readonly EXIT_KILOCODE_PROVIDER_ERROR=72
readonly EXIT_SIGNAL=124
```

**Recommendation**: 
- aidd-k could add `EXIT_NOT_FOUND`, `EXIT_PERMISSION_DENIED`, `EXIT_TIMEOUT`, `EXIT_ABORTED`, `EXIT_VALIDATION_ERROR` for consistency
- Or keep CLI-specific exit codes (current approach is acceptable)

---

## Prioritized Recommendations

### High Priority (Do Now)
1. **Standardize iteration state variable names**:
   - Change aidd-k to use `CURRENT_ITERATION`, `TOTAL_ITERATIONS`, `ITERATION_STATUS`, `ITERATION_START_TIME`, `ITERATION_END_TIME`
   - Add `ONBOARDING_COMPLETE` and `NEW_PROJECT_CREATED` to aidd-k
   - Remove `ITERATION_NUMBER`, `NEXT_LOG_INDEX`, `ITERATIONS_DIR`, `METADATA_DIR`, `SPEC_CHECK_PATH`, `FEATURE_LIST_CHECK_PATH` from aidd-k

2. **Standardize iteration state constants**:
   - Change aidd-k to use `STATE_IDLE`, `STATE_RUNNING`, `STATE_PAUSED`, `STATE_COMPLETED`, `STATE_FAILED`, `STATE_ABORTED`
   - Remove `STATE_NEW`, `STATE_IN_PROGRESS`, `STATE_COMPLETE` from aidd-k

### Medium Priority (Do Soon)
3. **Standardize exit code constants**:
   - Add missing exit codes to aidd-k for consistency
   - Consider creating a shared exit code module

4. **Create shared CLI patterns module**:
   - Extract common CLI patterns into `lib/cli.sh`
   - Both aidd-o and aidd-k could source this module

### Low Priority (Consider Later)
5. **Standardize phase constants**:
   - Keep current approaches as they're optimized for their respective CLIs
   - Document the differences clearly

6. **Create shared state management module**:
   - Extract common state management functions into `lib/state.sh`
   - Both scripts could source this module

## Implementation Plan

### Phase 1: Variable Naming (High Priority)
1. Update aidd-k to use standardized iteration state variable names
2. Add missing variables to aidd-k
3. Remove deprecated variables from aidd-k

### Phase 2: State Constants (High Priority)
1. Update aidd-k to use standardized state constants
2. Remove deprecated state constants from aidd-k

### Phase 3: Exit Codes (Medium Priority)
1. Add missing exit codes to aidd-k
2. Document CLI-specific exit codes

### Phase 4: Shared Modules (Low Priority)
1. Create `lib/cli.sh` with common CLI patterns
2. Create `lib/state.sh` with common state management
3. Update both scripts to source shared modules

## Benefits of Homogenization

### Maintainability
- **Easier to understand**: Consistent naming across all AIDD scripts
- **Easier to modify**: Changes follow the same patterns everywhere
- **Easier to debug**: Familiar patterns reduce cognitive load

### Code Quality
- **Reduced duplication**: Shared patterns extracted into common modules
- **Better organization**: Clear separation of concerns
- **Clearer interfaces**: Well-defined module boundaries

### User Experience
- **Consistent behavior**: All AIDD scripts behave similarly
- **Better error messages**: Consistent error reporting across all scripts
- **Better documentation**: Clear, comprehensive documentation

## Risks and Mitigation

### Risk: Breaking Changes
- **Mitigation**: Make changes incrementally, test thoroughly
- **Mitigation**: Keep backward compatibility where possible

### Risk: Increased Complexity
- **Mitigation**: Add clear documentation for new patterns
- **Mitigation**: Provide migration guide for existing code

## Conclusion

The aidd-o and aidd-k scripts have evolved independently to serve their respective CLIs (OpenCode and KiloCode). While some homogenization opportunities exist, the current differences are largely justified by the different workflows of each CLI.

**Recommendation**: Prioritize variable naming and state constant standardization (High Priority items) while keeping CLI-specific differences (phase constants, iteration flow) as they're optimized for their respective workflows.

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-07  
**Author**: Kilo Code  
**Status**: Draft for Review
