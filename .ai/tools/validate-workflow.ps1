[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$errors = [System.Collections.Generic.List[string]]::new()
$config = Import-PowerShellDataFile (Join-Path $root ".ai\config.psd1")
$archiveAfterDays = [int]$config.TaskArchiveAfterDays
$retrievalHalfLifeDays = [double]$config.RetrievalHalfLifeDays
$retrievalSoftLimit = [int]$config.RetrievalSoftTokenLimit
$retrievalHardLimit = [int]$config.RetrievalHardTokenLimit
$retrievalRuntimeLimit = [int]$config.RetrievalRuntimeTokenLimit
$retrievalMinimumScore = [double]$config.RetrievalMinimumScore
$retrievalMinimumExcerptTokens = [int]$config.RetrievalMinimumExcerptTokens
$retrievalMaxResults = [int]$config.RetrievalMaxResultsPerCategory
$retrievalArchiveFallbackMinimum = [int]$config.RetrievalArchiveFallbackMinimumActiveResults
$retrievalCategoryCaps = $config.RetrievalCategoryTokenCaps

function Add-ValidationError([string]$Message) {
    $errors.Add($Message)
}

if ($archiveAfterDays -lt 1 -or $archiveAfterDays -gt 3650) {
    Add-ValidationError ".ai/config.psd1 TaskArchiveAfterDays must be between 1 and 3650"
}
if ($retrievalHalfLifeDays -le 0) {
    Add-ValidationError ".ai/config.psd1 RetrievalHalfLifeDays must be greater than zero"
}
if ($retrievalSoftLimit -le 0 -or $retrievalHardLimit -le 0 -or $retrievalSoftLimit -gt $retrievalHardLimit) {
    Add-ValidationError ".ai/config.psd1 retrieval soft/hard token limits are invalid"
}
if ($retrievalRuntimeLimit -le 0 -or $retrievalRuntimeLimit -gt $retrievalSoftLimit) {
    Add-ValidationError ".ai/config.psd1 RetrievalRuntimeTokenLimit must be positive and no greater than RetrievalSoftTokenLimit"
}
if ($retrievalMinimumScore -lt 0 -or $retrievalMinimumScore -gt 1) {
    Add-ValidationError ".ai/config.psd1 RetrievalMinimumScore must be between 0 and 1"
}
if ($retrievalMinimumExcerptTokens -lt 1 -or $retrievalMaxResults -lt 1 -or $retrievalArchiveFallbackMinimum -lt 1) {
    Add-ValidationError ".ai/config.psd1 retrieval selection counts must be positive"
}

function Get-Text([string]$Path) {
    return [System.IO.File]::ReadAllText($Path)
}

function Test-DatedDecisionPath([string]$Path) {
    return $Path -match '^\.ai[\\/]decision[\\/]\d{4}-\d{2}-\d{2}-\d{3}-.+\.md$'
}

& cmd.exe /c "git -C \"$root\" rev-parse --verify --quiet HEAD >nul 2>nul"
$hasGitHead = $LASTEXITCODE -eq 0
if ((Test-Path (Join-Path $root ".git")) -and (Get-Command git -ErrorAction SilentlyContinue) -and $hasGitHead) {
	$decisionChanges = @(& git -C $root diff --name-status --diff-filter=DR HEAD -- .ai/decision 2>$null)
    foreach ($change in $decisionChanges) {
        $parts = $change -split "`t"
        if ($parts.Count -lt 2) {
            continue
        }

        $status = $parts[0]
        $oldPath = if ($status -match '^R') { $parts[1] } else { $parts[-1] }
        if (Test-DatedDecisionPath $oldPath) {
            Add-ValidationError "Dated decision records are append-only and must not be deleted or renamed: $oldPath. Add a superseding decision and update its latest route instead."
        }
    }
}

$markdownFiles = @((Join-Path $root "AGENTS.md")) + @(
    Get-ChildItem (Join-Path $root ".ai") -Recurse -File -Filter "*.md" |
        Select-Object -ExpandProperty FullName
)

foreach ($file in $markdownFiles) {
    $text = Get-Text $file
    foreach ($match in [regex]::Matches($text, '\[[^\]]+\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim()
        if ($target -match '^(https?://|mailto:|#)' -or $target -match '[<>]' -or $target.Contains('...')) {
            continue
        }

        $pathPart = ($target -split '#', 2)[0]
        if ([string]::IsNullOrWhiteSpace($pathPart)) {
            continue
        }

        $resolvedTarget = Join-Path (Split-Path $file -Parent) $pathPart
        if (-not (Test-Path $resolvedTarget)) {
            Add-ValidationError "Broken link in $($file.Substring($root.Length + 1)): $target"
        }
    }
}

$memoryUnits = [System.Collections.Generic.List[string]]::new()
$memoryUnits.Add((Join-Path $root ".ai\project.md"))
$memoryUnits.AddRange([string[]]@(Get-ChildItem (Join-Path $root ".ai\decision") -File -Filter "????-??-??-*.md" | Select-Object -ExpandProperty FullName))
$memoryUnits.AddRange([string[]]@(Get-ChildItem (Join-Path $root ".ai\tasks") -Recurse -File -Filter "????-??-??-*.md" | Select-Object -ExpandProperty FullName))
foreach ($directory in @("guides", "summaries")) {
    $memoryUnits.AddRange([string[]]@(
        Get-ChildItem (Join-Path $root ".ai\$directory") -File -Filter "*.md" |
            Where-Object { $_.Name -notin @("README.md", "_template.md") } |
            Select-Object -ExpandProperty FullName
    ))
}

$summaryFiles = @(
    Get-ChildItem (Join-Path $root ".ai\summaries") -File -Filter "*.md" |
        Where-Object { $_.Name -notin @("README.md", "_template.md") }
)
foreach ($summary in $summaryFiles) {
    $text = Get-Text $summary.FullName
    $sourcePathsMatch = [regex]::Match($text, '(?m)^- Source Paths:\s*(.+?)\s*$')
    if (-not $sourcePathsMatch.Success) {
        Add-ValidationError ".ai/summaries/$($summary.Name) has no Source Paths field"
        continue
    }

    $sourcePaths = @([regex]::Matches($sourcePathsMatch.Groups[1].Value, '`([^`]+)`') | ForEach-Object { $_.Groups[1].Value })
    if ($sourcePaths.Count -eq 0) {
        Add-ValidationError ".ai/summaries/$($summary.Name) has no concrete source path"
        continue
    }

    foreach ($sourcePath in $sourcePaths) {
        $resolvedSource = Join-Path $root $sourcePath
        if (-not (Test-Path $resolvedSource)) {
            Add-ValidationError ".ai/summaries/$($summary.Name) points to missing source: $sourcePath"
        } elseif ((Get-Item $resolvedSource).PSIsContainer -and -not (Get-ChildItem $resolvedSource -Recurse -File | Select-Object -First 1)) {
            Add-ValidationError ".ai/summaries/$($summary.Name) points to an empty source directory: $sourcePath"
        }
    }
}

$metadataPattern = '(?m)^- {0}:\s*(.+?)\s*$'
foreach ($file in $memoryUnits) {
    $text = Get-Text $file
    $relative = $file.Substring($root.Length + 1)
    foreach ($field in @("importance", "confidence", "createdAt", "lastUsedAt")) {
        $match = [regex]::Match($text, ($metadataPattern -f [regex]::Escape($field)))
        if (-not $match.Success) {
            Add-ValidationError "$relative is missing metadata: $field"
            continue
        }

        $value = $match.Groups[1].Value
        if ($field -in @("importance", "confidence")) {
            $number = 0.0
            if (-not [double]::TryParse($value, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$number) -or $number -lt 0 -or $number -gt 1) {
                Add-ValidationError "$relative has invalid ${field}: $value"
            }
        } else {
            $timestamp = [DateTimeOffset]::MinValue
            if (-not [DateTimeOffset]::TryParseExact($value, "yyyy-MM-dd'T'HH:mm:ss'Z'", [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$timestamp)) {
                Add-ValidationError "$relative has invalid $field timestamp: $value"
            }
        }
    }
}

$validStatuses = @("planned", "in-progress", "blocked", "completed", "cancelled")
$requiredTaskSections = @("Description", "Context", "Decisions", "Likely Files", "Files Touched", "Summary", "Validation", "Follow-up / Risks")
$activeTaskFiles = @(Get-ChildItem (Join-Path $root ".ai\tasks") -File -Filter "????-??-??-*.md")
$archivedTaskFiles = @(Get-ChildItem (Join-Path $root ".ai\tasks\archive") -File -Filter "????-??-??-*.md")
$taskFiles = @($activeTaskFiles) + @($archivedTaskFiles)
foreach ($task in $taskFiles) {
    $text = Get-Text $task.FullName
    $statusMatch = [regex]::Match($text, '(?m)^- Status:\s*(\S+)\s*$')
    if (-not $statusMatch.Success -or $statusMatch.Groups[1].Value -notin $validStatuses) {
        Add-ValidationError ".ai/tasks/$($task.Name) has a missing or invalid status"
    }
    foreach ($section in $requiredTaskSections) {
        if ($text -notmatch "(?m)^## $([regex]::Escape($section))\s*$") {
            Add-ValidationError ".ai/tasks/$($task.Name) is missing section: $section"
        }
    }
}

$currentPath = Join-Path $root ".ai\tasks\current.md"
$currentText = Get-Text $currentPath
$currentTaskMatch = [regex]::Match($currentText, '\[[^\]]+\]\(([^)]+)\)')
$currentStatusMatch = [regex]::Match($currentText, '(?m)^- Status:\s*(\S+)\s*$')
if (-not $currentTaskMatch.Success) {
    Add-ValidationError ".ai/tasks/current.md has no task link"
} else {
    $currentTaskPath = Join-Path (Split-Path $currentPath -Parent) $currentTaskMatch.Groups[1].Value
    if (-not (Test-Path $currentTaskPath)) {
        Add-ValidationError ".ai/tasks/current.md points to a missing task"
    } elseif ([System.IO.Path]::GetFullPath($currentTaskPath).StartsWith([System.IO.Path]::GetFullPath((Join-Path $root ".ai\tasks\archive")), [StringComparison]::OrdinalIgnoreCase)) {
        Add-ValidationError ".ai/tasks/current.md must not point into the task archive"
    } else {
        $targetStatusMatch = [regex]::Match((Get-Text $currentTaskPath), '(?m)^- Status:\s*(\S+)\s*$')
        if (-not $currentStatusMatch.Success -or -not $targetStatusMatch.Success -or $currentStatusMatch.Groups[1].Value -ne $targetStatusMatch.Groups[1].Value) {
            Add-ValidationError ".ai/tasks/current.md status does not match its target task"
        }

        $currentTaskText = Get-Text $currentTaskPath
        foreach ($decisionReference in [regex]::Matches($currentTaskText, '\.ai[\\/]decision[\\/]\d{4}-\d{2}-\d{2}-\d{3}-[^`\s)]+\.md') | ForEach-Object { $_.Value }) {
            $normalizedReference = $decisionReference.Replace('/', [System.IO.Path]::DirectorySeparatorChar).Replace('\\', [System.IO.Path]::DirectorySeparatorChar)
            if (-not (Test-Path (Join-Path $root $normalizedReference))) {
                Add-ValidationError ".ai/tasks/$([System.IO.Path]::GetFileName($currentTaskPath)) references a missing dated decision: $decisionReference. Dated decisions must be retained; add a superseding decision and update its latest route instead."
            }
        }
    }
}

$archiveCutoff = [DateTimeOffset]::UtcNow.AddDays(-$archiveAfterDays)
foreach ($task in $activeTaskFiles) {
    if ([System.IO.Path]::GetFullPath($task.FullName) -eq [System.IO.Path]::GetFullPath($currentTaskPath)) {
        continue
    }

    $text = Get-Text $task.FullName
    $statusMatch = [regex]::Match($text, '(?m)^- Status:\s*(\S+)\s*$')
    if (-not $statusMatch.Success -or $statusMatch.Groups[1].Value -notin @("completed", "cancelled")) {
        continue
    }

    $createdAtMatch = [regex]::Match($text, '(?m)^- createdAt:\s*(.+?)\s*$')
    $lastUsedAtMatch = [regex]::Match($text, '(?m)^- lastUsedAt:\s*(.+?)\s*$')
    if ($createdAtMatch.Success -and $lastUsedAtMatch.Success) {
        $createdAt = [DateTimeOffset]::ParseExact($createdAtMatch.Groups[1].Value, "yyyy-MM-dd'T'HH:mm:ss'Z'", [Globalization.CultureInfo]::InvariantCulture)
        $lastUsedAt = [DateTimeOffset]::ParseExact($lastUsedAtMatch.Groups[1].Value, "yyyy-MM-dd'T'HH:mm:ss'Z'", [Globalization.CultureInfo]::InvariantCulture)
        $referenceAt = if ($lastUsedAt -gt $createdAt) { $lastUsedAt } else { $createdAt }
        if ($referenceAt -le $archiveCutoff) {
            Add-ValidationError ".ai/tasks/$($task.Name) is eligible for archival after $archiveAfterDays days"
        }
    }
}

foreach ($task in $archivedTaskFiles) {
    $statusMatch = [regex]::Match((Get-Text $task.FullName), '(?m)^- Status:\s*(\S+)\s*$')
    if (-not $statusMatch.Success -or $statusMatch.Groups[1].Value -notin @("completed", "cancelled")) {
        Add-ValidationError ".ai/tasks/archive/$($task.Name) is archived with a nonterminal status"
    }
}

$readmeText = Get-Text (Join-Path $root ".ai\README.md")
$categoryNames = @("Project", "Architecture", "Decisions", "Previous Work", "Code")
$categoryTotal = 0
foreach ($name in $categoryNames) {
    $match = [regex]::Match($readmeText, "(?m)^\| $([regex]::Escape($name)) \| ([\d,]+) \|")
    if (-not $match.Success) {
        Add-ValidationError ".ai/README.md is missing the $name retrieval-budget row"
    } else {
        $documentedCap = [int]($match.Groups[1].Value.Replace(',', ''))
        $categoryTotal += $documentedCap
        if (-not $retrievalCategoryCaps.ContainsKey($name)) {
            Add-ValidationError ".ai/config.psd1 is missing the $name retrieval category cap"
        } elseif ([int]$retrievalCategoryCaps[$name] -ne $documentedCap) {
            Add-ValidationError ".ai/config.psd1 $name cap does not match .ai/README.md"
        }
    }
}
$totalMatch = [regex]::Match($readmeText, '(?m)^\| \*\*Total\*\* \| \*\*([\d,]+)\*\* \|')
if (-not $totalMatch.Success) {
    Add-ValidationError ".ai/README.md is missing the retrieval-budget total"
} elseif ($categoryTotal -ne [int]($totalMatch.Groups[1].Value.Replace(',', ''))) {
    Add-ValidationError ".ai/README.md retrieval-budget rows sum to $categoryTotal, not $($totalMatch.Groups[1].Value)"
}
if ($categoryTotal -ne $retrievalHardLimit) {
    Add-ValidationError ".ai/config.psd1 RetrievalHardTokenLimit does not match category-cap total $categoryTotal"
}

$softLimitMatch = [regex]::Match($readmeText, 'Use a ([\d,]+)-token soft limit')
if (-not $softLimitMatch.Success) {
    Add-ValidationError ".ai/README.md is missing the retrieval soft limit"
} elseif ([int]($softLimitMatch.Groups[1].Value.Replace(',', '')) -ne $retrievalSoftLimit) {
    Add-ValidationError ".ai/config.psd1 RetrievalSoftTokenLimit does not match .ai/README.md"
}

$runtimeLimitMatch = [regex]::Match($readmeText, 'default runtime-output limit is ([\d,]+) estimated tokens')
if (-not $runtimeLimitMatch.Success) {
    Add-ValidationError ".ai/README.md is missing the retrieval runtime-output limit"
} elseif ([int]($runtimeLimitMatch.Groups[1].Value.Replace(',', '')) -ne $retrievalRuntimeLimit) {
    Add-ValidationError ".ai/config.psd1 RetrievalRuntimeTokenLimit does not match .ai/README.md"
}

foreach ($toolName in @("archive-tasks.ps1", "retrieve-context.ps1", "validate-workflow.ps1")) {
    $toolPath = Join-Path $root ".ai\tools\$toolName"
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($toolPath, [ref]$tokens, [ref]$parseErrors)
    foreach ($parseError in $parseErrors) {
        Add-ValidationError ".ai/tools/$toolName has a PowerShell parse error: $($parseError.Message)"
    }
}

if ($errors.Count -gt 0) {
    Write-Host "AI workflow validation failed with $($errors.Count) error(s):" -ForegroundColor Red
    foreach ($validationError in $errors) {
        Write-Host "- $validationError" -ForegroundColor Red
    }
    exit 1
}

Write-Host "AI workflow validation passed: $($markdownFiles.Count) Markdown files, $($memoryUnits.Count) memory units, $($activeTaskFiles.Count) active task records, and $($archivedTaskFiles.Count) archived task records checked." -ForegroundColor Green