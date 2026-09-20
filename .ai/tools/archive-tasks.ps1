[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$ArchiveAfterDays = 0,

    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$config = Import-PowerShellDataFile (Join-Path $root ".ai\config.psd1")
if ($ArchiveAfterDays -eq 0) {
    $ArchiveAfterDays = [int]$config.TaskArchiveAfterDays
}
if ($ArchiveAfterDays -lt 1 -or $ArchiveAfterDays -gt 3650) {
    throw "ArchiveAfterDays must be between 1 and 3650."
}
$tasksPath = Join-Path $root ".ai\tasks"
$archivePath = Join-Path $tasksPath "archive"
$currentPath = Join-Path $tasksPath "current.md"
$cutoff = [DateTimeOffset]::UtcNow.AddDays(-$ArchiveAfterDays)

function Get-Text([string]$Path) {
    return [System.IO.File]::ReadAllText($Path)
}

function Get-Field([string]$Text, [string]$Name) {
    $match = [regex]::Match($Text, "(?m)^- $([regex]::Escape($Name)):\s*(.+?)\s*$")
    if (-not $match.Success) {
        throw "Missing required field '$Name'."
    }
    return $match.Groups[1].Value
}

function Get-RelativeMarkdownPath([string]$FromDirectory, [string]$ToPath) {
    $separator = [System.IO.Path]::DirectorySeparatorChar
    $fromWithSeparator = $FromDirectory.TrimEnd($separator, [System.IO.Path]::AltDirectorySeparatorChar) + $separator
    $fromUri = [Uri]$fromWithSeparator
    $toUri = [Uri]$ToPath
    return [Uri]::UnescapeDataString($fromUri.MakeRelativeUri($toUri).ToString())
}

function Convert-LinksForArchive([string]$Text, [string]$SourceDirectory, [string]$DestinationDirectory) {
    return [regex]::Replace($Text, '\[([^\]]+)\]\(([^)]+)\)', {
        param($match)

        $label = $match.Groups[1].Value
        $target = $match.Groups[2].Value.Trim()
        if ($target -match '^(https?://|mailto:|#)' -or $target -match '[<>]' -or $target.Contains('...')) {
            return $match.Value
        }

        $parts = $target -split '#', 2
        $pathPart = $parts[0]
        $fragment = if ($parts.Count -eq 2) { "#$($parts[1])" } else { "" }
        if ([string]::IsNullOrWhiteSpace($pathPart)) {
            return $match.Value
        }

        $absoluteTarget = [System.IO.Path]::GetFullPath((Join-Path $SourceDirectory $pathPart))
        if (-not (Test-Path $absoluteTarget)) {
            throw "Cannot archive a task with unresolved local link '$target'."
        }

        $relativeTarget = Get-RelativeMarkdownPath $DestinationDirectory $absoluteTarget
        return "[$label]($relativeTarget$fragment)"
    })
}

function Update-InboundTaskLinks([string]$SourcePath, [string]$DestinationPath) {
    $markdownFiles = @((Join-Path $root "AGENTS.md")) + @(
        Get-ChildItem (Join-Path $root ".ai") -Recurse -File -Filter "*.md" |
            Where-Object { $_.FullName -ne $SourcePath -and $_.FullName -ne $DestinationPath } |
            Select-Object -ExpandProperty FullName
    )
    $normalizedSource = [System.IO.Path]::GetFullPath($SourcePath)

    foreach ($markdownFile in $markdownFiles) {
        $originalText = Get-Text $markdownFile
        $updatedText = [regex]::Replace($originalText, '\[([^\]]+)\]\(([^)]+)\)', {
            param($match)

            $label = $match.Groups[1].Value
            $target = $match.Groups[2].Value.Trim()
            if ($target -match '^(https?://|mailto:|#)' -or $target -match '[<>]' -or $target.Contains('...')) {
                return $match.Value
            }

            $parts = $target -split '#', 2
            $pathPart = $parts[0]
            $fragment = if ($parts.Count -eq 2) { "#$($parts[1])" } else { "" }
            if ([string]::IsNullOrWhiteSpace($pathPart)) {
                return $match.Value
            }

            $absoluteTarget = [System.IO.Path]::GetFullPath((Join-Path (Split-Path $markdownFile -Parent) $pathPart))
            if ($absoluteTarget -ne $normalizedSource) {
                return $match.Value
            }

            $relativeTarget = Get-RelativeMarkdownPath (Split-Path $markdownFile -Parent) $DestinationPath
            return "[$label]($relativeTarget$fragment)"
        })

        if ($updatedText -ne $originalText) {
            [System.IO.File]::WriteAllText($markdownFile, $updatedText, [System.Text.UTF8Encoding]::new($false))
        }
    }
}

$currentText = Get-Text $currentPath
$currentMatch = [regex]::Match($currentText, '\[[^\]]+\]\(([^)]+)\)')
if (-not $currentMatch.Success) {
    throw ".ai/tasks/current.md has no task link."
}
$currentTaskPath = [System.IO.Path]::GetFullPath((Join-Path $tasksPath $currentMatch.Groups[1].Value))

$eligible = [System.Collections.Generic.List[object]]::new()
foreach ($task in Get-ChildItem $tasksPath -File -Filter "????-??-??-*.md") {
    if ($task.FullName -eq $currentTaskPath) {
        continue
    }

    $text = Get-Text $task.FullName
    $status = Get-Field $text "Status"
    if ($status -notin @("completed", "cancelled")) {
        continue
    }

    $createdAt = [DateTimeOffset]::ParseExact((Get-Field $text "createdAt"), "yyyy-MM-dd'T'HH:mm:ss'Z'", [Globalization.CultureInfo]::InvariantCulture)
    $lastUsedAt = [DateTimeOffset]::ParseExact((Get-Field $text "lastUsedAt"), "yyyy-MM-dd'T'HH:mm:ss'Z'", [Globalization.CultureInfo]::InvariantCulture)
    $referenceAt = if ($lastUsedAt -gt $createdAt) { $lastUsedAt } else { $createdAt }
    if ($referenceAt -le $cutoff) {
        $eligible.Add([pscustomobject]@{
            File = $task
            Text = $text
            ReferenceAt = $referenceAt
        })
    }
}

if ($CheckOnly) {
    if ($eligible.Count -gt 0) {
        Write-Host "$($eligible.Count) task record(s) are eligible for archival:" -ForegroundColor Yellow
        foreach ($item in $eligible) {
            Write-Host "- $($item.File.Name) (reference: $($item.ReferenceAt.ToString('yyyy-MM-ddTHH:mm:ssZ')))" -ForegroundColor Yellow
        }
        exit 1
    }

    Write-Host "Task archival check passed: no active task record is older than $ArchiveAfterDays days and eligible for archival." -ForegroundColor Green
    exit 0
}

if ($eligible.Count -eq 0) {
    Write-Host "No task records are eligible for archival after $ArchiveAfterDays days." -ForegroundColor Green
    exit 0
}

if (-not (Test-Path $archivePath) -and $PSCmdlet.ShouldProcess($archivePath, "Create task archive directory")) {
    New-Item -ItemType Directory -Path $archivePath | Out-Null
}

foreach ($item in $eligible) {
    $destination = Join-Path $archivePath $item.File.Name
    if (Test-Path $destination) {
        throw "Archive destination already exists: $destination"
    }

    if ($PSCmdlet.ShouldProcess($item.File.FullName, "Archive task to $destination")) {
        $archivedText = Convert-LinksForArchive $item.Text $tasksPath $archivePath
        [System.IO.File]::WriteAllText($destination, $archivedText, [System.Text.UTF8Encoding]::new($false))
        Update-InboundTaskLinks $item.File.FullName $destination
        Remove-Item $item.File.FullName
        Write-Host "Archived $($item.File.Name)" -ForegroundColor Green
    }
}

Write-Host "Archived $($eligible.Count) task record(s)." -ForegroundColor Green