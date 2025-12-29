#!/usr/bin/env pwsh

param(
	[Parameter(Mandatory = $false)]
	[switch]$Help,

	[Parameter(Mandatory = $false)]
	[string]$ProjectDir = '',

	[Parameter(Mandatory = $false)]
	[int]$MaxIterations = 0,  # 0 means unlimited

	[Parameter(Mandatory = $false)]
	[string]$Spec = '',

	[Parameter(Mandatory = $false)]
	[int]$Timeout = 600,  # Default to 600 seconds

	[Parameter(Mandatory = $false)]
	[int]$IdleTimeout = 180,

	[Parameter(Mandatory = $false)]
	[string]$Model = '',

	[Parameter(Mandatory = $false)]
	[string]$InitModel = '',

	[Parameter(Mandatory = $false)]
	[string]$CodeModel = '',

	[Parameter(Mandatory = $false)]
	[switch]$NoClean

	,
	[Parameter(Mandatory = $false)]
	[int]$QuitOnAbort = 0
)

# Show help if requested
if ($Help) {
	Write-Host 'Usage: aidd-k.ps1 -ProjectDir <dir> [-Spec <file>] [-MaxIterations <num>] [-Timeout <seconds>] [-IdleTimeout <seconds>] [-Model <model>] [-InitModel <model>] [-CodeModel <model>] [-NoClean] [-QuitOnAbort <num>] [-Help]'
	Write-Host ''
	Write-Host 'Options:'
	Write-Host '  -ProjectDir       Project directory (required)'
	Write-Host '  -Spec             Specification file (optional for existing codebases, required for new projects)'
	Write-Host '  -MaxIterations    Maximum iterations (optional, unlimited if not specified)'
	Write-Host '  -Timeout          Timeout in seconds (optional, default: 600)'
	Write-Host '  -IdleTimeout      Abort if kilocode produces no output for N seconds (optional, default: 180)'
	Write-Host '  -Model            Model to use (optional)'
	Write-Host '  -InitModel        Model to use for initializer/onboarding prompts (optional, overrides -Model)'
	Write-Host '  -CodeModel        Model to use for coding prompt (optional, overrides -Model)'
	Write-Host '  -NoClean          Skip log cleaning on exit (optional)'
	Write-Host '  -QuitOnAbort      Quit after N consecutive failures (optional, default: 0=continue indefinitely)'
	Write-Host '  -Help             Show this help message'
	Write-Host ''
	exit 0
}

# Check required parameters
if ($ProjectDir -eq '') {
	Write-Error 'Error: Missing required argument -ProjectDir'
	Write-Host 'Use -Help for usage information'
	exit 1
}

# Function to find or create metadata directory
function Find-OrCreateMetadataDir {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Directory
	)

	# Check for existing directories in order of preference
	$autoDir = Join-Path $Directory '.auto'
	if (Test-Path $autoDir -PathType Container) {
		return $autoDir
	}

	$autokDir = Join-Path $Directory '.autok'
	if (Test-Path $autokDir -PathType Container) {
		return $autokDir
	}

	$automakerDir = Join-Path $Directory '.automaker'
	if (Test-Path $automakerDir -PathType Container) {
		return $automakerDir
	}

	# Create .auto as default
	New-Item -Path $autoDir -ItemType Directory -Force | Out-Null
	return $autoDir
}

# Function to check if directory is an existing codebase
function Test-ExistingCodebase {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Directory
	)

	if (Test-Path $Directory -PathType Container) {
		# Check if directory has files excluding common ignored directories
		$hasFiles = Get-ChildItem -Path $Directory -Force | Where-Object {
			$_.Name -notin @('.git', '.auto', '.autok', '.automaker', '.DS_Store', 'node_modules', '.vscode', '.idea')
		} | Measure-Object | Select-Object -ExpandProperty Count

		return $hasFiles -gt 0
	}
	return $false
}

# Check if spec is required (only for new projects or when metadata dir doesn't have spec.txt)
$NeedsSpec = $false
$MetadataDir = Find-OrCreateMetadataDir -Directory $ProjectDir
if ((-not (Test-Path $ProjectDir -PathType Container)) -or (-not (Test-ExistingCodebase -Directory $ProjectDir))) {
	$NeedsSpec = $true
}

if ($NeedsSpec -and $Spec -eq '') {
	Write-Error 'Error: Missing required argument -Spec (required for new projects or when spec.txt does not exist)'
	Write-Host 'Use -Help for usage information'
	exit 1
}

$effectiveInitModel = $Model
if ($InitModel -ne '') { $effectiveInitModel = $InitModel }

$effectiveCodeModel = $Model
if ($CodeModel -ne '') { $effectiveCodeModel = $CodeModel }

$noAssistantPattern = 'The model returned no assistant messages'
$providerErrorPattern = 'Provider returned error'

function Invoke-KilocodePrompt {
	param(
		[Parameter(Mandatory = $true)]
		[string]$ProjectDir,

		[Parameter(Mandatory = $true)]
		[string]$PromptPath,

		[Parameter(Mandatory = $false)]
		[string]$EffectiveModel
	)

	$kilocodeArgs = @('--mode', 'code', '--auto', '--timeout', $Timeout, '--nosplash')
	if ($EffectiveModel -ne '') { $kilocodeArgs += @('--model', $EffectiveModel) }

	$psi = [System.Diagnostics.ProcessStartInfo]::new()
	$psi.FileName = 'kilocode'
	foreach ($arg in $kilocodeArgs) {
		$psi.ArgumentList.Add([string]$arg) | Out-Null
	}
	$psi.WorkingDirectory = $ProjectDir
	$psi.RedirectStandardInput = $true
	$psi.RedirectStandardOutput = $true
	$psi.RedirectStandardError = $true
	$psi.UseShellExecute = $false
	$psi.CreateNoWindow = $true

	$p = [System.Diagnostics.Process]::new()
	$p.StartInfo = $psi

	$lastOutputAt = [DateTimeOffset]::UtcNow
	$sawNoAssistant = $false
	$sawProviderError = $false

	$onOutput = {
		param([string]$line)
		if ($null -eq $line) { return }
		$script:lastOutputAt = [DateTimeOffset]::UtcNow
		Write-Output $line
		if ($line -like "*$script:noAssistantPattern*") {
			$script:sawNoAssistant = $true
			try { $script:p.Kill() } catch { }
		}
		if ($line -like "*$script:providerErrorPattern*") {
			$script:sawProviderError = $true
			try { $script:p.Kill() } catch { }
		}
	}

	Register-ObjectEvent -InputObject $p -EventName OutputDataReceived -Action { & $using:onOutput $EventArgs.Data } | Out-Null
	Register-ObjectEvent -InputObject $p -EventName ErrorDataReceived -Action { & $using:onOutput $EventArgs.Data } | Out-Null

	$started = $p.Start()
	if (-not $started) { return 1 }
	$p.BeginOutputReadLine()
	$p.BeginErrorReadLine()

	try {
		$promptText = Get-Content -Path $PromptPath -Raw
		$p.StandardInput.Write($promptText)
		$p.StandardInput.Close()
	} catch {
		try { $p.Kill() } catch { }
		return 1
	}

	while (-not $p.HasExited) {
		Start-Sleep -Milliseconds 200
		if (([DateTimeOffset]::UtcNow - $lastOutputAt).TotalSeconds -ge $IdleTimeout) {
			Write-Error "aidd-k.ps1: idle timeout (${IdleTimeout}s) waiting for kilocode output; aborting."
			try { $p.Kill() } catch { }
			$p.WaitForExit()
			return 71
		}
	}

	if ($sawNoAssistant) { return 70 }
	if ($sawProviderError) { return 72 }

	return $p.ExitCode
}

function Get-NextIterationLogIndex {
	param(
		[Parameter(Mandatory = $true)]
		[string]$IterationsDir
	)

	$max = 0
	if (Test-Path $IterationsDir -PathType Container) {
		Get-ChildItem -Path $IterationsDir -Filter '*.log' -File -ErrorAction SilentlyContinue | ForEach-Object {
			$name = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
			if ($name -match '^[0-9]+$') {
				$num = [int]$name
				if ($num -gt $max) { $max = $num }
			}
		}
	}

	return ($max + 1)
}

# Function to clean logs on exit
function Clear-IterationLogs {
	param(
		[Parameter(Mandatory = $true)]
		[string]$IterationsDir
	)

	if ($NoClean) {
		Write-Host 'Skipping log cleanup (-NoClean flag set).'
		return
	}

	Write-Host 'Cleaning iteration logs...'
	if ((Test-Path $IterationsDir -PathType Container) -and (Get-ChildItem -Path $IterationsDir -Filter '*.log' -File -ErrorAction SilentlyContinue)) {
		$CleanLogsScript = Join-Path $PSScriptRoot 'clean-logs.js'
		& node $CleanLogsScript $IterationsDir --no-backup
		Write-Host 'Log cleanup complete.'
	}
}

# Function to copy artifacts to metadata directory
function Copy-Artifacts {
	param(
		[Parameter(Mandatory = $true)]
		[string]$ProjectDir
	)

	$ProjectMetadataDir = Find-OrCreateMetadataDir -Directory $ProjectDir
	Write-Host "Copying artifacts to '$ProjectMetadataDir'..."
	$ArtifactsSource = Join-Path $PSScriptRoot 'artifacts'
	New-Item -ItemType Directory -Path $ProjectMetadataDir -Force | Out-Null
	# Copy all artifacts contents, but don't overwrite existing files
	Get-ChildItem -Path $ArtifactsSource -Force | ForEach-Object {
		$DestinationPath = Join-Path $ProjectMetadataDir $_.Name
		if (-not (Test-Path $DestinationPath)) {
			Copy-Item -Path $_.FullName -Destination $ProjectMetadataDir -Recurse
		}
	}
}

# Set up trap to clean logs on script exit (both normal and interrupted)
$cleanupScript = {
	Clear-IterationLogs -IterationsDir $IterationsDir
}
# Register cleanup for normal exit, Ctrl+C, and script termination
try {
	$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action $cleanupScript -ErrorAction SilentlyContinue
} catch { }
# Handle Ctrl+C
[Console]::TreatControlCAsInput = $false

# Ensure project directory exists (create if missing)
if (-not (Test-Path $ProjectDir -PathType Container)) {
	Write-Host "Project directory '$ProjectDir' does not exist; creating it..."
	New-Item -ItemType Directory -Path $ProjectDir -Force | Out-Null
	$script:NewProjectCreated = $true

	# Copy scaffolding files to the new project directory (including hidden files)
	Write-Host "Copying scaffolding files to '$ProjectDir'..."
	$ScaffoldingSource = Join-Path $PSScriptRoot 'scaffolding'
	# Copy both regular and hidden files
	Get-ChildItem -Path $ScaffoldingSource -Force | ForEach-Object {
		Copy-Item -Path $_.FullName -Destination $ProjectDir -Recurse -Force
	}

	# Copy artifacts contents to project's metadata folder
	Write-Host "Copying artifacts to '$MetadataDir'..."
	$ArtifactsSource = Join-Path $PSScriptRoot 'artifacts'
	New-Item -ItemType Directory -Path $MetadataDir -Force | Out-Null
	# Copy all artifacts contents
	Get-ChildItem -Path $ArtifactsSource -Force | ForEach-Object {
		Copy-Item -Path $_.FullName -Destination $MetadataDir -Recurse -Force
	}
} else {
	$script:NewProjectCreated = $false
	# Check if this is an existing codebase
	if (Test-ExistingCodebase -Directory $ProjectDir) {
		Write-Host "Detected existing codebase in '$ProjectDir'"
	}
}

# Check if spec file exists (only if provided)
if ($Spec -ne '' -and (-not (Test-Path $Spec -PathType Leaf))) {
	Write-Error "Error: Spec file '$Spec' does not exist"
	exit 1
}

# Define the paths to check
$SpecCheckPath = Join-Path $MetadataDir 'spec.txt'
$FeatureListCheckPath = Join-Path $MetadataDir 'feature_list.json'

# Iteration transcript logs
$IterationsDir = Join-Path $MetadataDir 'iterations'
New-Item -ItemType Directory -Path $IterationsDir -Force | Out-Null
$NextLogIndex = Get-NextIterationLogIndex -IterationsDir $IterationsDir

$ConsecutiveFailures = 0

# Check for metadata dir/spec.txt
try {
	if ($MaxIterations -eq 0) {
		Write-Host 'Running unlimited iterations (use Ctrl+C to stop)'
		$i = 1
		while ($true) {
			$logFile = Join-Path $IterationsDir ('{0}.log' -f $NextLogIndex.ToString('D3'))
			$NextLogIndex++

			Write-Host "Iteration $i"
			Write-Host "Transcript: $logFile"
			Write-Host "Started: $(Get-Date -Format o)"

			try {
				Start-Transcript -Path $logFile -Force | Out-Null

				# Check if onboarding is already complete
				$OnboardingComplete = $false
				if (Test-Path $FeatureListCheckPath -PathType Leaf) {
					# Check if feature_list.json contains actual data (not just template)
					$content = Get-Content $FeatureListCheckPath -Raw
					if ($content -notmatch '\{yyyy-mm-dd\}' -and $content -notmatch '\{Short name of the feature\}') {
						$OnboardingComplete = $true
					}
				}

				$kilocodeExitCode = 0
				if (-not (Test-Path $SpecCheckPath -PathType Leaf) -or -not (Test-Path $FeatureListCheckPath -PathType Leaf) -or -not $OnboardingComplete) {
					if ((-not $script:NewProjectCreated) -and (Test-ExistingCodebase -Directory $ProjectDir) -and ((-not (Test-Path "$MetadataDir/spec.txt" -PathType Leaf)) -or (-not (Test-Path "$MetadataDir/feature_list.json" -PathType Leaf)) -or -not $OnboardingComplete)) {
						if (-not $OnboardingComplete) {
							Write-Host 'Detected incomplete onboarding, resuming onboarding prompt...'
						} else {
							Write-Host 'Detected existing codebase, using onboarding prompt...'
						}
						Copy-Artifacts -ProjectDir $ProjectDir
						$kilocodeExitCode = Invoke-KilocodePrompt -ProjectDir $ProjectDir -PromptPath "$PSScriptRoot/prompts/onboarding.md" -EffectiveModel $effectiveInitModel
					} else {
						Write-Host 'Required files not found, copying spec and sending initializer prompt...'
						Copy-Artifacts -ProjectDir $ProjectDir
						if ($Spec -ne '') {
							Copy-Item $Spec $SpecCheckPath
						}
						$kilocodeExitCode = Invoke-KilocodePrompt -ProjectDir $ProjectDir -PromptPath "$PSScriptRoot/prompts/initializer.md" -EffectiveModel $effectiveInitModel
					}
				} else {
					Write-Host 'Required files found, sending coding prompt...'
					$kilocodeExitCode = Invoke-KilocodePrompt -ProjectDir $ProjectDir -PromptPath "$PSScriptRoot/prompts/coding.md" -EffectiveModel $effectiveCodeModel
				}

				if ($kilocodeExitCode -ne 0) {
					$ConsecutiveFailures++
					Write-Error "aidd-k.ps1: kilocode failed (exit=$kilocodeExitCode); this is failure #$ConsecutiveFailures."
					if ($QuitOnAbort -gt 0 -and $ConsecutiveFailures -ge $QuitOnAbort) {
						Write-Error "aidd-k.ps1: reached failure threshold ($QuitOnAbort); quitting."
						exit $kilocodeExitCode
					}
					Write-Error "aidd-k.ps1: continuing to next iteration (threshold: $QuitOnAbort)."
				} else {
					$ConsecutiveFailures = 0
				}

				Write-Host "--- End of iteration $i ---"
				Write-Host "Finished: $(Get-Date -Format o)"
				Write-Host ''
			} finally {
				try { Stop-Transcript | Out-Null } catch { }
			}

			$i++
		}
	} else {
		Write-Host "Running $MaxIterations iterations"
		for ($i = 1; $i -le $MaxIterations; $i++) {
			$logFile = Join-Path $IterationsDir ('{0}.log' -f $NextLogIndex.ToString('D3'))
			$NextLogIndex++

			Write-Host "Iteration $i of $MaxIterations"
			Write-Host "Transcript: $logFile"
			Write-Host "Started: $(Get-Date -Format o)"

			try {
				Start-Transcript -Path $logFile -Force | Out-Null

				# Check if onboarding is already complete
				$OnboardingComplete = $false
				if (Test-Path $FeatureListCheckPath -PathType Leaf) {
					# Check if feature_list.json contains actual data (not just template)
					$content = Get-Content $FeatureListCheckPath -Raw
					if ($content -notmatch '\{yyyy-mm-dd\}' -and $content -notmatch '\{Short name of the feature\}') {
						$OnboardingComplete = $true
					}
				}

				$kilocodeExitCode = 0
				if (-not (Test-Path $SpecCheckPath -PathType Leaf) -or -not (Test-Path $FeatureListCheckPath -PathType Leaf) -or -not $OnboardingComplete) {
					if ((-not $script:NewProjectCreated) -and (Test-ExistingCodebase -Directory $ProjectDir) -and ((-not (Test-Path "$MetadataDir/spec.txt" -PathType Leaf)) -or (-not (Test-Path "$MetadataDir/feature_list.json" -PathType Leaf)) -or -not $OnboardingComplete)) {
						if (-not $OnboardingComplete) {
							Write-Host 'Detected incomplete onboarding, resuming onboarding prompt...'
						} else {
							Write-Host 'Detected existing codebase, using onboarding prompt...'
						}
						Copy-Artifacts -ProjectDir $ProjectDir
						$kilocodeExitCode = Invoke-KilocodePrompt -ProjectDir $ProjectDir -PromptPath "$PSScriptRoot/prompts/onboarding.md" -EffectiveModel $effectiveInitModel
					} else {
						Write-Host 'Required files not found, copying spec and sending initializer prompt...'
						Copy-Artifacts -ProjectDir $ProjectDir
						if ($Spec -ne '') {
							Copy-Item $Spec $SpecCheckPath
						}
						$kilocodeExitCode = Invoke-KilocodePrompt -ProjectDir $ProjectDir -PromptPath "$PSScriptRoot/prompts/initializer.md" -EffectiveModel $effectiveInitModel
					}
				} else {
					Write-Host 'Required files found, sending coding prompt...'
					$kilocodeExitCode = Invoke-KilocodePrompt -ProjectDir $ProjectDir -PromptPath "$PSScriptRoot/prompts/coding.md" -EffectiveModel $effectiveCodeModel
				}

				if ($kilocodeExitCode -ne 0) {
					$ConsecutiveFailures++
					Write-Error "aidd-k.ps1: kilocode failed (exit=$kilocodeExitCode); this is failure #$ConsecutiveFailures."
					if ($QuitOnAbort -gt 0 -and $ConsecutiveFailures -ge $QuitOnAbort) {
						Write-Error "aidd-k.ps1: reached failure threshold ($QuitOnAbort); quitting."
						exit $kilocodeExitCode
					}
					Write-Error "aidd-k.ps1: continuing to next iteration (threshold: $QuitOnAbort)."
				} else {
					$ConsecutiveFailures = 0
				}

				# If this is not the last iteration, add a separator
				if ($i -lt $MaxIterations) {
					Write-Host "--- End of iteration $i ---"
					Write-Host "Finished: $(Get-Date -Format o)"
					Write-Host ''
				} else {
					Write-Host "Finished: $(Get-Date -Format o)"
					Write-Host ''
				}
			} finally {
				try { Stop-Transcript | Out-Null } catch { }
			}
		}
	}
} finally {
	# Ensure cleanup runs even on error or interruption
	Clear-IterationLogs -IterationsDir $IterationsDir
}
