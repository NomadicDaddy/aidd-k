## TOOL AVAILABILITY

**Filesystem is MCP-first (mandatory):** use the Filesystem MCP server for read/write/edit/list/search/move/metadata/tree.

If a needed filesystem operation is not supported by MCP tooling, and only then, use `execute_command`.

| Group            | Tools                                                                                                                                                                                                                                                                                                                                               | Purpose                                      |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------- |
| Filesystem (MCP) | mcp_filesystem_read_text_file, mcp_filesystem_read_multiple_files, mcp_filesystem_write_file, mcp_filesystem_edit_file, mcp_filesystem_create_directory, mcp_filesystem_list_directory, mcp_filesystem_directory_tree, mcp_filesystem_search_files, mcp_filesystem_move_file, mcp_filesystem_get_file_info, mcp_filesystem_list_allowed_directories | All filesystem work                          |
| Code intel       | list_code_definition_names                                                                                                                                                                                                                                                                                                                          | Quick mapping (top-level only per directory) |
| Browser          | browser_action                                                                                                                                                                                                                                                                                                                                      | UI verification                              |
| Command          | execute_command                                                                                                                                                                                                                                                                                                                                     | Git / package managers / starting services   |
| Workflow         | switch_mode, new_task, attempt_completion, update_todo_list                                                                                                                                                                                                                                                                                         | Task management                              |

### Usage

- If a tool is unavailable, fall back to `execute_command` (shell), adjust the workflow, or document what you could not do.
- Do not assume bash is available; use commands appropriate for the active shell (PowerShell/cmd/bash).
- Tool names are exact and case-sensitive (e.g. use `new_task`, not `newTask`).
- When using `execute_command`, never pass a `cwd` value of `null`/`"null"`. If you want the workspace default working directory, **omit `cwd` entirely**.
- Once you identify the project root, prefer running all `execute_command` calls with an explicit `cwd` set to that project root if it's different from the workspace default, if same **omit `cwd` entirely**.
- Never invent tool names - only use those listed here.

**IMPORTANT: `list_code_definition_names` only processes files at the top level of the specified directory, not subdirectories.** To explore subdirectories, you must call `list_code_definition_names` on each subdirectory path individually.

## FILE EDIT SAFETY PROTOCOL

1. **Read immediately before editing:** `mcp_filesystem_read_text_file`.
2. Prefer `mcp_filesystem_edit_file` for targeted changes; use `mcp_filesystem_write_file` only for full rewrites.
3. **Read immediately after editing** to confirm the final file is correct.
4. If corruption occurs, rollback via git:

```bash
git checkout -- <file-path>
```

## Filesystem MCP Tools Documentation

### read_text_file

Read complete contents of a file as text

**Inputs:**

- `path` (string)
- `head` (number, optional): First N lines
- `tail` (number, optional): Last N lines

**Notes:**

- Always treats the file as UTF-8 text regardless of extension
- Cannot specify both head and tail simultaneously

---

## read_media_file

Read an image or audio file

**Inputs:**

- `path` (string)

**Returns:**

- Streams the file and returns base64 data with the corresponding MIME type

---

## read_multiple_files

Read multiple files simultaneously

**Inputs:**

- `paths` (string[])

**Notes:**

- Failed reads won't stop the entire operation

---

## write_file

Create new file or overwrite existing (exercise caution with this)

**Inputs:**

- `path` (string): File location
- `content` (string): File content

---

## edit_file

Make selective edits using advanced pattern matching and formatting

**Features:**

- Line-based and multi-line content matching
- Whitespace normalization with indentation preservation
- Multiple simultaneous edits with correct positioning
- Indentation style detection and preservation
- Git-style diff output with context
- Preview changes with dry run mode

**Inputs:**

- `path` (string): File to edit
- `edits` (array): List of edit operations
- `oldText` (string): Text to search for (can be substring)
- `newText` (string): Text to replace with
- `dryRun` (boolean): Preview changes without applying (default: false)

**Returns:**

- Detailed diff and match information for dry runs, otherwise applies changes

**Best Practice:** Always use dryRun first to preview changes before applying them

---

## create_directory

Create new directory or ensure it exists

**Inputs:**

- `path` (string)

**Notes:**

- Creates parent directories if needed
- Succeeds silently if directory exists

---

## list_directory

List directory contents with [FILE] or [DIR] prefixes

**Inputs:**

- `path` (string)

---

## list_directory_with_sizes

List directory contents with [FILE] or [DIR] prefixes, including file sizes

**Inputs:**

- `path` (string): Directory path to list
- `sortBy` (string, optional): Sort entries by "name" or "size" (default: "name")

**Returns:**

- Detailed listing with file sizes and summary statistics
- Shows total files, directories, and combined size

---

## move_file

Move or rename files and directories

**Inputs:**

- `source` (string)
- `destination` (string)

**Notes:**

- Fails if destination exists

---

## search_files

Recursively search for files/directories that match or do not match patterns

**Inputs:**

- `path` (string): Starting directory
- `pattern` (string): Search pattern
- `excludePatterns` (string[]): Exclude any patterns

**Notes:**

- Glob-style pattern matching
- Returns full paths to matches

---

## directory_tree

Get recursive JSON tree structure of directory contents

**Inputs:**

- `path` (string): Starting directory
- `excludePatterns` (string[]): Exclude any patterns. Glob formats are supported.

**Returns:**
JSON array where each entry contains:

- `name` (string): File/directory name
- `type` ('file'|'directory'): Entry type
- `children` (array): Present only for directories
    - Empty array for empty directories
    - Omitted for files

**Output:** Formatted with 2-space indentation for readability

---

## get_file_info

Get detailed file/directory metadata

**Inputs:**

- `path` (string)

**Returns:**

- Size
- Creation time
- Modified time
- Access time
- Type (file/directory)
- Permissions

---

## list_allowed_directories

List all directories the server is allowed to access

**Inputs:**

- None required

**Returns:**

- Directories that this server can read/write from
