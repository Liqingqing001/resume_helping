param(
  [string]$SkillsDirectory = $(if ($env:CODEX_HOME) { Join-Path $env:CODEX_HOME 'skills' } else { Join-Path $env:USERPROFILE '.codex\skills' }),
  [Parameter(Mandatory=$true)][string]$Workspace
)
$ErrorActionPreference = 'Stop'

# Run from a downloaded repository. Never connect to a browser during setup.
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  throw 'Install Node.js 22 or newer, reopen PowerShell, and try again.'
}
$nodeMajor = & node -p 'Number(process.versions.node.split(".")[0])'
$webSocketType = & node -p 'typeof WebSocket'
if ($LASTEXITCODE -ne 0 -or [int]$nodeMajor -lt 22 -or $webSocketType -ne 'function') {
  throw 'Node.js 22 or newer with global WebSocket support is required.'
}
$source = Join-Path $PSScriptRoot 'job-application-assistant'
$target = [IO.Path]::GetFullPath((Join-Path $SkillsDirectory 'job-application-assistant'))
$workRoot = [IO.Path]::GetFullPath($Workspace)
$configPath = Join-Path $workRoot 'profile.local.json'
if (Test-Path -LiteralPath $target) { throw "Skill already exists: $target. Back it up and merge manually; nothing was overwritten." }
if (Test-Path -LiteralPath $configPath) { throw "Configuration already exists: $configPath. Nothing was overwritten." }
$config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'profile.example.json') -Raw | ConvertFrom-Json
$config.profile_root = Join-Path $workRoot 'profile'
$config.resume_pdf = Join-Path $workRoot 'output\resume.pdf'
$config.receipt_directory = Join-Path $workRoot 'receipts'
foreach ($folder in @($SkillsDirectory, $workRoot, $config.profile_root, (Join-Path $workRoot 'output'), $config.receipt_directory, (Join-Path $workRoot 'tmp'))) {
  New-Item -ItemType Directory -Path $folder -Force | Out-Null
}
Copy-Item -LiteralPath $source -Destination $target -Recurse
$utf8 = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 10), $utf8)
Write-Output "Installed skill: $target"
Write-Output "Configuration: $configPath"
Write-Output 'Add your own confirmed profile and resume PDF. Empty configuration is not a completed resume.'
Write-Output 'Open a new Codex chat in your workspace and invoke $job-application-assistant.'
Write-Output 'Browser login and remote-debugging approval are still required for website operations.'
