# AutoK2 - Autonomous Development Orchestrator

A bash shell script that orchestrates autonomous development sessions using Kilocode AI.

## Usage

```bash
./autok2.sh --project-dir <dir> --spec <file> [--max-iterations <num>] [--timeout <seconds>] [--model <model>]
```

### Required Arguments
- `--project-dir`: Target project directory
- `--spec`: Specification file to copy to project-dir/.autok/spec.txt

### Optional Arguments
- `--max-iterations`: Number of iterations to run (unlimited if not specified)
- `--timeout`: Timeout in seconds for each kilocode session (default: 6000)
- `--model`: Model to use (optional)

## How It Works

The script runs in a loop based on max-iterations:

1. Checks if both `project-dir/.autok/spec.txt` AND `project-dir/.autok/feature_list.json` exist
2. If either is missing:
   - Creates `.autok` directory if needed
   - Copies the provided spec file to `project-dir/.autok/spec.txt`
   - Sends initializer prompt to kilocode
3. If both exist:
   - Sends coding prompt to kilocode

## Example

```bash
./autok2.sh --project-dir ../auto-test --max-iterations 1 --spec ./specs/heystack.txt --timeout 600
```

## Prompts Used

- **Initializer prompt**: `cat ./prompts/initializer.md | kilocode --auto --timeout <timeout>`
- **Coding prompt**: `cat ./prompts/coding.md | kilocode --auto --timeout <timeout>`

Both prompts are executed from within the project directory to ensure proper context.

## PowerShell Version

A PowerShell version (`autok2.ps1`) is also available with the same functionality:

```powershell
./autok2.ps1 -ProjectDir "../auto-test" -MaxIterations 1 -Spec "./specs/heystack.txt" -Timeout 600
```
