# AIDD Log Cleaner

A Node.js script to clean up `.aidd/iterations` logs by removing extraneous terminal artifacts and noise while preserving the meaningful content. (Legacy `.autok/iterations` directories can still be cleaned—just point the script at the old path.)

## Features

- Removes ANSI escape sequences and terminal control characters
- Removes terminal title/control fragments commonly found in captured output
- Removes common terminal UI border-only lines (box drawing characters)
- Deduplicates consecutive identical lines
- Trims trailing whitespace and reduces excessive blank lines
- Preserves the original line content aside from the transformations above

## Usage

### Basic Usage

```bash
# Clean all logs in a directory (creates backups)
node clean-logs.js D:\applications\aidd-todo\.aidd\iterations

# Clean a single log file
node clean-logs.js D:\applications\aidd-todo\.aidd\iterations\001.log
```

### Advanced Options

```bash
# Clean logs without creating backups
node clean-logs.js D:\applications\aidd-todo\.aidd\iterations --no-backup

# Write cleaned logs to a different directory
node clean-logs.js D:\applications\aidd-todo\.aidd\iterations --output-dir cleaned-logs

# Show help
node clean-logs.js --help
```

## What Gets Cleaned

1. **Terminal Control Sequences**: All ANSI escape codes, cursor movements, screen clears
2. **Terminal Titles**: `]0;...` sequences that set terminal window titles
3. **UI Artifacts**:
    - Standalone border lines composed of box-drawing characters
    - The "Group | Tools" availability table block
4. **Noise**: Duplicate consecutive lines, excessive empty lines, trailing whitespace

## Example Results

Typical size reduction varies depending on how much terminal UI content is present.

```
Original: 316,400 bytes → Cleaned: 183,141 bytes (42.1% reduction)
Original: 574,457 bytes → Cleaned: 329,878 bytes (42.6% reduction)
```

## Requirements

- Node.js (ES module support)
- No external dependencies

## Installation

1. Save `clean-logs.js` to your desired location
2. Make sure you have Node.js installed
3. Run the script as shown above

## Safety

- By default, creates `.backup` files before overwriting
- Use `--no-backup` to overwrite originals (use with caution)
- Can output to a separate directory to keep originals intact

## License

MIT License - feel free to use and modify as needed.
