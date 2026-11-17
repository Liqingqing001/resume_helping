param(
  [ValidateSet('Codex', 'Claude', 'Cursor', 'All')]
  [string]$Agent = 'All',
  [string]$SkillsDirectory,
  [Parameter(Mandatory = $true)][string]$Workspace
)
$ErrorActionPreference = 'Stop'

# Install the skill folder for local agents. Default -Agent is All.
# Does not connect to a browser. Does not overwrite an existing skill folder
# or profile.local.json.
#
# Directories checked against vendor docs on 2026-11-17. Do not add a path
# that those docs do not state.
# - Codex user skills: $HOME/.agents/skills
#   https://learn.chatgpt.com/docs/build-skills.md
#   That page does not print a separate Windows path. %USERPROFILE% is used
#   as $HOME. CODEX_HOME (default ~/.codex) is a different documented root
#   and is not written unless -SkillsDirectory points there.
# - Claude Code personal skills: ~/.claude/skills, or $CLAUDE_CONFIG_DIR/skills
#   when CLAUDE_CONFIG_DIR is set.
#   https://code.claude.com/docs/en/claude-directory
#   On Windows, ~/.claude is %USERPROFILE%\.claude.
#   Claude Desktop Cowork has no documented folder for this copy.
# - Cursor user skills: ~/.cursor/skills
#   https://cursor.com/docs/skills
#   That page does not print a separate Windows path. %USERPROFILE% is used
#   as ~.

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  throw 'Install Node.js 22 or newer, reopen PowerShell, and try again.'
}
$nodeMajor = & node -p 'Number(process.versions.node.split(".")[0])'
$webSocketType = & node -p 'typeof WebSocket'
if ($LASTEXITCODE -ne 0 -or [int]$nodeMajor -lt 22 -or $webSocketType -ne 'function') {
  throw 'Node.js 22 or newer with global WebSocket support is required.'
}

function Get-VerifiedSkillRoots {
  param([Parameter(Mandatory = $true)][string]$SelectedAgent)
  $userProfile = $env:USERPROFILE
  if ([string]::IsNullOrWhiteSpace($userProfile)) {
    throw 'USERPROFILE is not set. Pass -SkillsDirectory to choose the skills folder.'
  }
  $roots = New-Object System.Collections.Generic.List[string]
  if ($SelectedAgent -eq 'Codex' -or $SelectedAgent -eq 'All') {
    $roots.Add((Join-Path (Join-Path $userProfile '.agents') 'skills'))
  }
  if ($SelectedAgent -eq 'Claude' -or $SelectedAgent -eq 'All') {
    if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_CONFIG_DIR)) {
      $roots.Add((Join-Path $env:CLAUDE_CONFIG_DIR 'skills'))
    } else {
      $roots.Add((Join-Path (Join-Path $userProfile '.claude') 'skills'))
    }
  }
  if ($SelectedAgent -eq 'Cursor' -or $SelectedAgent -eq 'All') {
    $roots.Add((Join-Path (Join-Path $userProfile '.cursor') 'skills'))
  }
  if ($roots.Count -eq 0) {
    throw "No verified skills directory for agent: $SelectedAgent"
  }
  foreach ($root in $roots) {
    Write-Output $root
  }
}

$source = Join-Path $PSScriptRoot 'job-application-assistant'
if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md') -PathType Leaf)) {
  throw "Skill source not found: $source. Run install.ps1 from the downloaded repository."
}

$agentWasChosen = $PSBoundParameters.ContainsKey('Agent')
$hasDirectoryOverride = -not [string]::IsNullOrWhiteSpace($SkillsDirectory)
if ($hasDirectoryOverride -and $agentWasChosen -and $Agent -eq 'All') {
  throw '-SkillsDirectory installs into one folder. Pass -Agent Codex, Claude, or Cursor, or omit -SkillsDirectory to install -Agent All.'
}

if ($hasDirectoryOverride) {
  $skillRoots = @([IO.Path]::GetFullPath($SkillsDirectory))
} else {
  $skillRoots = @(Get-VerifiedSkillRoots -SelectedAgent $Agent)
}

$targets = New-Object System.Collections.Generic.List[string]
$seenTargets = @{}
foreach ($root in $skillRoots) {
  if ([string]::IsNullOrWhiteSpace($root)) {
    throw 'A skills directory resolved to an empty path.'
  }
  if (Test-Path -LiteralPath $root -PathType Leaf) {
    throw "Skills directory is a file: $root"
  }
  $target = [IO.Path]::GetFullPath((Join-Path $root 'job-application-assistant'))
  $key = $target.ToLowerInvariant()
  if ($seenTargets.ContainsKey($key)) { continue }
  $seenTargets[$key] = $true
  $targets.Add($target)
}

$workRoot = [IO.Path]::GetFullPath($Workspace)
$configPath = Join-Path $workRoot 'profile.local.json'
foreach ($target in $targets) {
  if (Test-Path -LiteralPath $target) {
    throw "Skill already exists: $target. Back it up and merge manually; nothing was overwritten."
  }
}
if (Test-Path -LiteralPath $configPath) {
  throw "Configuration already exists: $configPath. Nothing was overwritten."
}

$config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'profile.example.json') -Raw | ConvertFrom-Json
$config.profile_root = Join-Path $workRoot 'profile'
$config.resume_pdf = Join-Path $workRoot 'output\resume.pdf'
$config.receipt_directory = Join-Path $workRoot 'receipts'

$folders = New-Object System.Collections.Generic.List[string]
foreach ($folder in @(
    $workRoot,
    $config.profile_root,
    (Join-Path $workRoot 'output'),
    $config.receipt_directory,
    (Join-Path $workRoot 'tmp')
  )) {
  $folders.Add($folder)
}
foreach ($target in $targets) {
  $folders.Add([IO.Path]::GetDirectoryName($target))
}
foreach ($folder in $folders) {
  New-Item -ItemType Directory -Path $folder -Force | Out-Null
}
foreach ($target in $targets) {
  Copy-Item -LiteralPath $source -Destination $target -Recurse
  if (-not (Test-Path -LiteralPath (Join-Path $target 'SKILL.md') -PathType Leaf)) {
    throw "Install did not produce SKILL.md: $target"
  }
  Write-Output "Installed skill: $target"
}

$utf8 = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 10), $utf8)
Write-Output "Configuration: $configPath"
Write-Output 'Add your own confirmed profile and resume PDF. Empty configuration is not a completed resume.'
Write-Output 'Open a new local chat in the workspace. Codex: $job-application-assistant. Claude Code: /job-application-assistant. Cursor Agent: /job-application-assistant.'
Write-Output 'Browser login and remote-debugging approval are still required for website operations.'
Write-Output 'Website steps need this Windows machine, Node.js 22, and the logged-in Edge. Cloud or hosted agents cannot attach to that Edge. Those steps are verified with Codex only.'
if ($hasDirectoryOverride) {
  Write-Output 'Installed only into -SkillsDirectory. The verified Codex, Claude, and Cursor folders were not used.'
} else {
  if ($Agent -eq 'Codex' -or $Agent -eq 'All') {
    Write-Output 'Codex folder is %USERPROFILE%\.agents\skills from the Codex skills table, not %CODEX_HOME%\skills. Cursor also loads ~/.agents/skills.'
  }
  if ($Agent -eq 'Claude' -or $Agent -eq 'All') {
    Write-Output 'Claude folder is Claude Code personal skills. Cowork does not read it, and no separate Claude Desktop folder is documented. Desktop scheduled tasks do load ~/.claude/skills. Cursor also loads ~/.claude/skills.'
  }
  if ($Agent -eq 'All') {
    Write-Output 'After -Agent All, Cursor may list this skill more than once.'
  }
}
