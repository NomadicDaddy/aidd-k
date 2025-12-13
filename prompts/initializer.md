## YOUR ROLE - INITIALIZER AGENT (Session 1 of Many)

You are in Code mode and ready to begin setting up the foundation for all future development workflows.
Your job is to create the foundational structure that enables strategic workflow orchestration and multi-mode coordination.

**CRITICAL: STOP AFTER INITIALIZATION**
After completing the tasks below, you MUST STOP. Do NOT implement any features.
Do NOT write any application code. Only create the setup files listed below.

### TOOL AVAILABILITY (READ FIRST)

Kilo Code CLI provides a fixed set of tools. Only instruct yourself to use tools that are actually available:

| Group    | Tools                                                           | Purpose            |
| -------- | --------------------------------------------------------------- | ------------------ |
| Read     | read_file, search_files, list_files, list_code_definition_names | Code exploration   |
| Edit     | apply_diff, delete_file                                         | File modifications |
| Browser  | browser_action                                                  | Web automation     |
| Command  | execute_command                                                 | System commands    |
| MCP      | use_mcp_tool, access_mcp_resource                               | External services  |
| Workflow | switch_mode, new_task, attempt_completion, update_todo_list     | Task management    |

## Usage

- If a tool is unavailable, fall back to `execute_command` (shell), adjust the workflow, or document what you could not do.
- Do not assume bash is available; use commands appropriate for the active shell (PowerShell/cmd/bash).
- Tool names are exact and case-sensitive (e.g. use `delete_file`, not `deleteFile`).
- When using `execute_command`, never pass a `cwd` value of `null`/`"null"`. If you want the workspace default working directory, **omit `cwd` entirely**.
- Once you identify the project root, prefer running all `execute_command` calls with an explicit `cwd` set to that project root.
- Prefer using `read_file` / `apply_diff` / `delete_file` for file operations. Use `execute_command` with shell redirection (e.g., `Set-Content` in PowerShell) when creating complete files or when tools misbehave.
- Never invent tool names - only use those listed here

## Common Patterns

- Information: ask_followup_question → read_file → search_files
- Code changes: read_file → apply_diff → attempt_completion
- Tasks: new_task → switch_mode → execute_command
- Progress: update_todo_list → execute_command → update_todo_list

### STEP 1: GET YOUR BEARINGS (MANDATORY)

Start by orienting yourself:

- Use `list_files` / `search_files` / `read_file` to locate and inspect `.autok/spec.txt`.
- Record the directory that contains `.autok/spec.txt` as your **project root**.
- Use that project root as the `cwd` for all subsequent `execute_command` calls.

Sanity check: after selecting the project root, `list_files` at that path should show expected entries (e.g. `.autok/`, `backend/`, `frontend/`, `scripts/`). If `list_files` shows `0 items` unexpectedly, stop and re-check the path (use `search_files` again or confirm with `execute_command`).

### STEP 2: Create .autok/feature_list.json

Based on `.autok/spec.txt`, create a file called `.autok/feature_list.json` with 20 detailed end-to-end test cases. This file is the single source of truth for what needs to be built.

**CRITICAL: ACCURATE FEATURE TRACKING**

The feature list must accurately reflect the specification:

1. **Spec Alignment:**
    - Read the spec carefully to understand the application type (e.g., todo list, user management, chat app)
    - Ensure ALL features directly correspond to spec requirements
    - Do NOT include features not mentioned in the spec
    - Do NOT omit any major functionality described in the spec

2. **Initial Status:**
    - ALL features MUST start with "passes": false
    - NO exceptions - even if setup seems trivial
    - Features are only marked "passing" after full implementation and testing

3. **Preventing False Positives:**
    - Never mark features as passing during initialization
    - Each feature must have concrete, testable steps
    - Tests must verify actual functionality, not just code presence

After writing `.autok/feature_list.json`, immediately `read_file` it to confirm it is valid JSON and matches the required structure.

**Format:**

```json
[
	{
		"category": "functional",
		"description": "Brief description of the feature and what this test verifies",
		"passes": false,
		"steps": [
			"Step 1: Navigate to relevant page",
			"Step 2: Perform action",
			"Step 3: Verify expected result"
		]
	},
	{
		"category": "style",
		"description": "Brief description of UI/UX requirement",
		"passes": false,
		"steps": [
			"Step 1: Navigate to page",
			"Step 2: Take screenshot",
			"Step 3: Verify visual requirements"
		]
	}
]
```

**Requirements for .autok/feature_list.json:**

- Minimum 20 features total with testing steps for each
- Both "functional" and "style" categories
- Mix of narrow tests (2-5 steps) and comprehensive tests (10+ steps)
- At least 2-5 tests MUST have 10+ steps each
- Order features by priority: fundamental features first
- ALL tests start with "passes": false
- Cover every feature in the spec exhaustively
- Ensure tests align with the actual application type defined in the spec

**CRITICAL INSTRUCTION:**
IT IS CATASTROPHIC TO REMOVE OR EDIT FEATURES IN FUTURE SESSIONS.
Features can ONLY be marked as passing (change "passes": false to "passes": true).
Never remove features, never edit descriptions, never modify testing steps.
This ensures no functionality is missed.

**WARNING:** Inaccurate feature tracking (marking unimplemented features as passing) leads to false confidence and prevents proper progress tracking. Always verify actual implementation before updating status.

### STEP 2.5: Create .autok/scaffolding-manifest.json (NEW MANDATORY STEP)

**CRITICAL: Create an explicit record of what scaffolding was set up.**

This manifest serves as the handoff document between sessions and ensures the coding agent knows exactly what's been initialized.

**Create scaffolding-manifest.json with:**

```json
{
	"configuration": {
		"build scripts": "configured",
		"eslint config": "created",
		"tsconfig files": "created"
	},
	"coreFiles": {
		"README.md": "created",
		"backend/package.json": "created",
		"frontend/package.json": "created",
		"package.json": "created"
	},
	"created": "2024-01-01T12:00:00Z",
	"directories": {
		"backend/": "created",
		"docs/": "created",
		"frontend/": "created",
		"scripts/": "created"
	},
	"nextSteps": [
		"Implement data models from spec",
		"Create API routes for core features",
		"Build UI components for features"
	],
	"specSpecific": {
		"auth components": "created",
		"main route files": "created as placeholders",
		"placeholder components": "created for major features",
		"schema.prisma": "created with base models"
	},
	"specType": "todo-list|user-management|chat-app|etc"
}
```

**Requirements for scaffolding-manifest.json:**

- List ALL directories and files created during initialization
- Mark spec-specific items clearly (models, routes, components)
- Include what's missing or needs to be implemented
- Be honest about what was vs wasn't set up
- This prevents false assumptions about what exists

After creating the manifest, immediately `read_file` to verify it's valid JSON.

### STEP 3: Create scripts/setup.ts

If a `scripts/setup.ts` file already exists, skip this task.

Otherwise, create one that initializes the development environment:

1. Install any required dependencies
2. Validate prerequisites (ports, env vars, required binaries) and create any required local config files
3. Print helpful information about how to start the application

Base the script on the technology stack specified in `.autok/spec.txt`.

After creating or editing `scripts/setup.ts`, immediately `read_file` it to confirm the intended contents were written.

**Important:** This initializer session must not start servers. The setup script should print the commands a later session can run to start the app.

### STEP 4: Execute scripts/setup.ts

Run the setup script with the following parameters:

slug: project_dir basename (e.g., "myapp" for directory "myapp/")
name: application name from spec
description: application description from spec
frontendPort: default 3330 unless specified in spec
backendPort: default 3331 unless specified in spec

If `scripts/setup.ts` exists, run it:

```bash
bun scripts/setup.ts --slug {slug} --name "{name}" --description "{description}" --frontend-port {frontendPort} --backend-port {backendPort}
```

### STEP 5: Create Project Structure

Set up the basic project structure based on what's specified in `.autok/spec.txt`.
This typically includes directories for frontend, backend, and any other components mentioned in the spec that do not yet exist.

### STEP 6: Create README.md

Create a comprehensive README.md that includes:

1. Project overview
2. Setup instructions
3. How to run the application
4. Any other relevant information

### STEP 7: Initialize Git

Create a git repository and make your first commit with:

- .autok/feature_list.json (complete with all 20 features)
- scripts/setup.ts (environment setup script)
- README.md (project overview and setup instructions)

Commit message: "Initial setup: .autok/feature_list.json, scripts/setup.ts, and project structure"

Note: Run git commands via `execute_command`, adapting to the current shell.

### STEP 8: ENDING THIS SESSION

**STOP IMMEDIATELY AFTER COMPLETING TASKS ABOVE**

Before your context fills up:

1. Commit all work with descriptive messages using execute_command
2. Create `.autok/progress.txt` with a summary of what you accomplished (create it if missing)
3. Ensure .autok/feature_list.json is complete and saved
4. Leave the environment in a clean state
5. Use attempt_completion to present final results

**DO NOT IMPLEMENT ANY FEATURES**
**DO NOT WRITE APPLICATION CODE**
**DO NOT START SERVERS**

The next agent will continue from here with a fresh context window.
