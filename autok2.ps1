#!/usr/bin/env pwsh

param(
	[Parameter(Mandatory = $true)]
	[string]$ProjectDir,

	[Parameter(Mandatory = $false)]
	[int]$MaxIterations = 0,  # 0 means unlimited

	[Parameter(Mandatory = $true)]
	[string]$Spec,

	[Parameter(Mandatory = $false)]
	[int]$Timeout = 6000,  # Default to 6000 seconds

	[string]$Model = ''
)

# Check if project directory exists
if (-not (Test-Path $ProjectDir -PathType Container)) {
	Write-Error "Error: Project directory '$ProjectDir' does not exist"
	exit 1
}

# Check if spec file exists
if (-not (Test-Path $Spec -PathType Leaf)) {
	Write-Error "Error: Spec file '$Spec' does not exist"
	exit 1
}

# Define the paths to check
$SpecCheckPath = Join-Path $ProjectDir '.autok/spec.txt'
$FeatureListCheckPath = Join-Path $ProjectDir '.autok/feature_list.json'

# Check for project_dir/.autok/spec.txt
if ($MaxIterations -eq 0) {
	Write-Host 'Running unlimited iterations (use Ctrl+C to stop)'
	$i = 1
	while ($true) {
		Write-Host "Iteration $i"

		if (-not (Test-Path $SpecCheckPath -PathType Leaf) -or -not (Test-Path $FeatureListCheckPath -PathType Leaf)) {
			Write-Host 'Required files not found, copying spec and sending initializer prompt...'
			# Create .autok directory if it doesn't exist
			New-Item -ItemType Directory -Path "$ProjectDir/.autok" -Force | Out-Null
			# Copy spec file to project directory
			Copy-Item $Spec $SpecCheckPath
			# Send initializer prompt from project directory
			Push-Location $ProjectDir
			Get-Content "$PSScriptRoot/prompts/initializer.md" | kilocode --auto --timeout $Timeout
			Pop-Location
		} else {
			Write-Host 'Required files found, sending coding prompt...'
			# Send coding prompt from project directory
			Push-Location $ProjectDir
			Get-Content "$PSScriptRoot/prompts/coding.md" | kilocode --auto --timeout $Timeout
			Pop-Location
		}

		Write-Host "--- End of iteration $i ---"
		Write-Host ''
		$i++
	}
} else {
	Write-Host "Running $MaxIterations iterations"
	for ($i = 1; $i -le $MaxIterations; $i++) {
		Write-Host "Iteration $i of $MaxIterations"

		if (-not (Test-Path $SpecCheckPath -PathType Leaf) -or -not (Test-Path $FeatureListCheckPath -PathType Leaf)) {
			Write-Host 'Required files not found, copying spec and sending initializer prompt...'
			# Create .autok directory if it doesn't exist
			New-Item -ItemType Directory -Path "$ProjectDir/.autok" -Force | Out-Null
			# Copy spec file to project directory
			Copy-Item $Spec $SpecCheckPath
			# Send initializer prompt from project directory
			Push-Location $ProjectDir
			Get-Content "$PSScriptRoot/prompts/initializer.md" | kilocode --auto --timeout $Timeout
			Pop-Location
		} else {
			Write-Host 'Required files found, sending coding prompt...'
			# Send coding prompt from project directory
			Push-Location $ProjectDir
			Get-Content "$PSScriptRoot/prompts/coding.md" | kilocode --auto --timeout $Timeout
			Pop-Location
		}

		# If this is not the last iteration, add a separator
		if ($i -lt $MaxIterations) {
			Write-Host "--- End of iteration $i ---"
			Write-Host ''
		}
	}
}
