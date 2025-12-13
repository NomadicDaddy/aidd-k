# AutoK - Autonomous Development Orchestrator

A bash shell script that orchestrates autonomous development sessions using Kilocode AI.

## Specifications

AutoK uses project specifications in Markdown format aligned with Spernakit template standards. All specs are located in the `specs/` directory with `.md` extensions.

## Usage

```bash
./autok.sh --project-dir <dir> --spec <file> [--max-iterations <num>] [--timeout <seconds>] [--model <model>]
```

### Required Arguments
- `--project-dir`: Target project directory
- `--spec`: Specification file (.md) to copy to project-dir/.autok/spec.txt

### Optional Arguments
- `--max-iterations`: Number of iterations to run (unlimited if not specified)
- `--timeout`: Timeout in seconds for each kilocode session (default: 600)
- `--model`: Model to use (optional)

## How It Works

The script runs in a loop based on max-iterations:

1. Checks if both `project-dir/.autok/spec.txt` AND `project-dir/.autok/feature_list.json` exist
2. Creates a per-iteration transcript log at `project-dir/.autok/iterations/001.log`, `002.log`, ...
   - The log index is chosen as the next number after the highest existing numeric `*.log` in that directory
   - Logs are not overwritten across re-runs
2. If either is missing:
   - Creates `.autok` directory if needed
   - Copies the provided spec file to `project-dir/.autok/spec.txt`
   - Sends initializer prompt to kilocode
3. If both exist:
   - Sends coding prompt to kilocode

## Iteration Transcripts

Each iteration writes a transcript file under:

- `project-dir/.autok/iterations/001.log`
- `project-dir/.autok/iterations/002.log`
- ...

The transcript captures the console output for that iteration (including `kilocode` output).

## Example

```bash
./autok.sh --project-dir ../autok-test --max-iterations 1 --spec ./specs/heystack.md --timeout 6000
```

## Prompts Used

- **Initializer prompt**: `cat ./prompts/initializer.md | kilocode --auto --timeout <timeout>`
- **Coding prompt**: `cat ./prompts/coding.md | kilocode --auto --timeout <timeout>`

Both prompts are executed from within the project directory to ensure proper context.

## PowerShell Version

A PowerShell version (`autok.ps1`) is also available with the same functionality:

```powershell
./autok.ps1 -ProjectDir "../autok-test" -MaxIterations 10 -Spec "./specs/heystack.md"
```

The PowerShell version also writes per-iteration transcripts to `project-dir/.autok/iterations/`.
