[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Query,

    [ValidateSet("Markdown", "Json")]
    [string]$Format = "Markdown",

    [ValidateSet("Auto", "Never", "Always")]
    [string]$ArchiveMode = "Auto",

    [switch]$IncludeCode,

    [string[]]$CodeRoots = @("src"),

    [ValidateRange(1000, 24000)]
    [int]$TokenLimit = 0,

    [ValidateRange(1, 50)]
    [int]$MaxResultsPerCategory = 0,

    [switch]$IncludeContent,

    [switch]$PathsOnly
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$config = Import-PowerShellDataFile (Join-Path $root ".ai\config.psd1")

if ($TokenLimit -eq 0) {
    $TokenLimit = [int]$config.RetrievalRuntimeTokenLimit
}
if ($MaxResultsPerCategory -eq 0) {
    $MaxResultsPerCategory = [int]$config.RetrievalMaxResultsPerCategory
}

$halfLifeDays = [double]$config.RetrievalHalfLifeDays
$minimumScore = [double]$config.RetrievalMinimumScore
$minimumExcerptTokens = [int]$config.RetrievalMinimumExcerptTokens
$archiveFallbackMinimum = [int]$config.RetrievalArchiveFallbackMinimumActiveResults
$categoryCaps = $config.RetrievalCategoryTokenCaps
if ($TokenLimit -gt [int]$config.RetrievalHardTokenLimit) {
    throw "TokenLimit cannot exceed the configured hard limit of $($config.RetrievalHardTokenLimit)."
}
if ($IncludeContent -and $PathsOnly) {
    throw "IncludeContent and PathsOnly cannot be used together. Compact lead output is already the default."
}
$contentMode = [bool]$IncludeContent

$stopWords = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
@(
    "a", "an", "and", "are", "as", "at", "be", "been", "before", "but", "by", "can", "do", "for", "from",
    "had", "has", "have", "how", "i", "if", "in", "into", "is", "it", "its", "make", "of", "on", "or", "our",
    "should", "so", "some", "than", "that", "the", "their", "then", "there", "these", "this", "to", "use", "was",
    "we", "what", "when", "where", "which", "will", "with", "would", "you", "your"
) | ForEach-Object { [void]$stopWords.Add($_) }

$synonymGroups = @(
    @("archive", "archival", "history", "historical", "retention"),
    @("retrieve", "retrieval", "search", "find", "lookup", "context"),
    @("orchestrator", "orchestration", "runtime", "pipeline", "workflow"),
    @("summary", "summaries", "overview", "system"),
    @("decision", "decisions", "choice", "policy", "rule"),
    @("task", "tasks", "work", "previous"),
    @("token", "tokens", "budget", "limit", "context"),
    @("rank", "ranking", "score", "relevance", "semantic"),
    @("validate", "validation", "validator", "integrity", "check"),
    @("source", "code", "implementation", "script"),
    @("client", "local", "frontend"),
    @("server", "backend", "service"),
    @("save", "persist", "persistence", "datastore", "data"),
    @("ui", "gui", "interface", "screen")
)

function Get-Text([string]$Path) {
    return [System.IO.File]::ReadAllText($Path)
}

function Get-RelativePath([string]$Path) {
    return $Path.Substring($root.Length + 1).Replace('\', '/')
}

function Get-Terms([string]$Text) {
    $terms = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $normalized = [regex]::Replace($Text, '(?<=[a-z0-9])(?=[A-Z])', ' ').ToLowerInvariant()
    foreach ($match in [regex]::Matches($normalized, '[a-z0-9][a-z0-9_-]{1,}')) {
        foreach ($part in $match.Value -split '[-_]') {
            if ($part.Length -ge 2 -and -not $stopWords.Contains($part)) {
                [void]$terms.Add($part)
            }
        }
    }
    return @($terms)
}

function Get-ExpandedTerms([string[]]$Terms) {
    $expanded = @{}
    foreach ($term in $Terms) {
        $expanded[$term] = 1.0
        foreach ($group in $synonymGroups) {
            if ($term -in $group) {
                foreach ($synonym in $group) {
                    if (-not $expanded.ContainsKey($synonym) -or $expanded[$synonym] -lt 0.65) {
                        $expanded[$synonym] = 0.65
                    }
                }
            }
        }
    }
    return $expanded
}

function Get-Field([string]$Text, [string]$Name, [string]$Default) {
    $match = [regex]::Match($Text, "(?m)^- $([regex]::Escape($Name)):\s*(.+?)\s*$")
    if ($match.Success) {
        return $match.Groups[1].Value
    }
    return $Default
}

function Get-Title([string]$Text, [string]$Fallback) {
    $match = [regex]::Match($Text, '(?m)^#\s+(.+?)\s*$')
    if ($match.Success) {
        return $match.Groups[1].Value
    }
    return $Fallback
}

function Get-EstimatedTokens([string]$Text) {
    if ([string]::IsNullOrEmpty($Text)) {
        return 0
    }
    return [int][Math]::Ceiling($Text.Length / 4.0)
}

function Get-Similarity([string]$Title, [string]$RelativePath, [string]$Text, [hashtable]$ExpandedTerms) {
    if ($ExpandedTerms.Count -eq 0) {
        return 0.0
    }

    $titleTerms = [System.Collections.Generic.HashSet[string]]::new([string[]](Get-Terms $Title), [StringComparer]::OrdinalIgnoreCase)
    $pathTerms = [System.Collections.Generic.HashSet[string]]::new([string[]](Get-Terms $RelativePath), [StringComparer]::OrdinalIgnoreCase)
    $textTerms = [System.Collections.Generic.HashSet[string]]::new([string[]](Get-Terms $Text), [StringComparer]::OrdinalIgnoreCase)
    $possible = 0.0
    $matched = 0.0

    foreach ($entry in $ExpandedTerms.GetEnumerator()) {
        $term = [string]$entry.Key
        $weight = [double]$entry.Value
        $possible += $weight
        if ($titleTerms.Contains($term)) {
            $matched += $weight
        } elseif ($pathTerms.Contains($term)) {
            $matched += $weight * 0.9
        } elseif ($textTerms.Contains($term)) {
            $matched += $weight * 0.7
        }
    }

    return [Math]::Min(1.0, $matched / $possible)
}

function Get-MemoryCandidate([string]$Path, [string]$Category, [bool]$Archived, [bool]$Mandatory) {
    $text = Get-Text $Path
    $relativePath = Get-RelativePath $Path
    $title = Get-Title $text ([System.IO.Path]::GetFileNameWithoutExtension($Path))
    $similarity = if ($Mandatory) { 1.0 } else { Get-Similarity $title $relativePath $text $expandedTerms }
    $importance = [double](Get-Field $text "importance" "0.5")
    $confidence = [double](Get-Field $text "confidence" "0.5")
    $createdAt = [DateTimeOffset]::Parse((Get-Field $text "createdAt" "2000-01-01T00:00:00Z"), [Globalization.CultureInfo]::InvariantCulture)
    $lastUsedAt = [DateTimeOffset]::Parse((Get-Field $text "lastUsedAt" $createdAt.ToString("yyyy-MM-ddTHH:mm:ssZ")), [Globalization.CultureInfo]::InvariantCulture)
    $referenceAt = if ($lastUsedAt -gt $createdAt) { $lastUsedAt } else { $createdAt }
    $ageDays = [Math]::Max(0.0, ([DateTimeOffset]::UtcNow - $referenceAt).TotalDays)
    $recencyFactor = [Math]::Pow(2.0, -$ageDays / $halfLifeDays)
    $score = if ($Mandatory) { 1.0 } else { $similarity * $importance * $confidence * $recencyFactor }

    return [pscustomobject]@{
        Path = $Path
        RelativePath = $relativePath
        Title = $title
        Category = $Category
        Archived = $Archived
        Mandatory = $Mandatory
        Similarity = $similarity
        Importance = $importance
        Confidence = $confidence
        CreatedAt = $createdAt
        LastUsedAt = $lastUsedAt
        RecencyFactor = $recencyFactor
        Score = $score
        FullText = $text
        EstimatedTokens = Get-EstimatedTokens $text
    }
}

function Get-CodeCandidate([string]$Path) {
    $text = Get-Text $Path
    $relativePath = Get-RelativePath $Path
    $title = [System.IO.Path]::GetFileName($Path)
    $similarity = Get-Similarity $title $relativePath $text $expandedTerms
    return [pscustomobject]@{
        Path = $Path
        RelativePath = $relativePath
        Title = $title
        Category = "Code"
        Archived = $false
        Mandatory = $false
        Similarity = $similarity
        Importance = 1.0
        Confidence = 1.0
        CreatedAt = [DateTimeOffset]::MinValue
        LastUsedAt = [DateTimeOffset]::MinValue
        RecencyFactor = 1.0
        Score = $similarity
        FullText = $text
        EstimatedTokens = Get-EstimatedTokens $text
    }
}

function Get-FocusedExcerpt([string]$Text, [int]$MaxTokens, [string[]]$Terms) {
    $maxCharacters = [Math]::Max(0, $MaxTokens * 4)
    if ($Text.Length -le $maxCharacters) {
        return $Text
    }
    if ($maxCharacters -lt 80) {
        return ""
    }

    $firstIndex = -1
    foreach ($term in $Terms) {
        $index = $Text.IndexOf($term, [StringComparison]::OrdinalIgnoreCase)
        if ($index -ge 0 -and ($firstIndex -lt 0 -or $index -lt $firstIndex)) {
            $firstIndex = $index
        }
    }
    if ($firstIndex -lt 0) {
        $firstIndex = 0
    }

    $start = [Math]::Max(0, $firstIndex - [int]($maxCharacters * 0.25))
    $length = [Math]::Min($maxCharacters, $Text.Length - $start)
    $excerpt = $Text.Substring($start, $length)
    if ($start -gt 0) {
        $excerpt = "...`n" + $excerpt
    }
    if ($start + $length -lt $Text.Length) {
        $excerpt += "`n..."
    }
    return $excerpt
}

function Select-Candidates([object[]]$Candidates, [int]$CategoryCap, [int]$GlobalRemaining) {
    $selected = [System.Collections.Generic.List[object]]::new()
    $remaining = [Math]::Min($CategoryCap, $GlobalRemaining)
    $count = 0

    $ordered = @($Candidates | Sort-Object @{ Expression = "Mandatory"; Descending = $true }, @{ Expression = "Score"; Descending = $true }, @{ Expression = "LastUsedAt"; Descending = $true }, @{ Expression = "CreatedAt"; Descending = $true })
    foreach ($candidate in $ordered) {
        if ($count -ge $MaxResultsPerCategory -and -not $candidate.Mandatory) {
            continue
        }
        if (-not $candidate.Mandatory -and $candidate.Score -lt $minimumScore) {
            continue
        }
        if ($contentMode) {
            if ($remaining -lt $minimumExcerptTokens) {
                break
            }
            $allowed = [Math]::Min($candidate.EstimatedTokens, $remaining)
            if ($allowed -lt $minimumExcerptTokens -and $allowed -lt $candidate.EstimatedTokens -and -not $candidate.Mandatory) {
                continue
            }
            $content = Get-FocusedExcerpt $candidate.FullText $allowed $queryTerms
            if ($content.Length -gt ($allowed * 4)) {
                $content = $content.Substring(0, $allowed * 4)
            }
            $actualTokens = Get-EstimatedTokens $content
            $truncated = $allowed -lt $candidate.EstimatedTokens
        } else {
            $content = ""
            $actualTokens = Get-EstimatedTokens "$($candidate.RelativePath) $($candidate.Title)"
            $truncated = $false
            if ($actualTokens -gt $remaining) {
                continue
            }
        }
        $selected.Add([pscustomobject]@{
            Path = $candidate.RelativePath
            Title = $candidate.Title
            Category = $candidate.Category
            Archived = $candidate.Archived
            Mandatory = $candidate.Mandatory
            Similarity = [Math]::Round($candidate.Similarity, 4)
            Importance = $candidate.Importance
            Confidence = $candidate.Confidence
            RecencyFactor = [Math]::Round($candidate.RecencyFactor, 4)
            Score = [Math]::Round($candidate.Score, 6)
            EstimatedTokens = $actualTokens
            Truncated = $truncated
            Content = $content
        })
        $remaining -= $actualTokens
        $count++
    }

    return @($selected)
}

$queryTerms = Get-Terms $Query
$expandedTerms = Get-ExpandedTerms $queryTerms
$tasksPath = Join-Path $root ".ai\tasks"
$currentText = Get-Text (Join-Path $tasksPath "current.md")
$currentMatch = [regex]::Match($currentText, '\[[^\]]+\]\(([^)]+)\)')
if (-not $currentMatch.Success) {
    throw ".ai/tasks/current.md has no task link."
}
$currentTaskPath = [System.IO.Path]::GetFullPath((Join-Path $tasksPath $currentMatch.Groups[1].Value))
$currentTaskRelativePath = Get-RelativePath $currentTaskPath

$candidates = [System.Collections.Generic.List[object]]::new()
$candidates.Add((Get-MemoryCandidate (Join-Path $root ".ai\project.md") "Project" $false $true))

foreach ($file in Get-ChildItem (Join-Path $root ".ai\guides") -File -Filter "*.md" | Where-Object { $_.Name -notin @("README.md", "_template.md") }) {
    $candidates.Add((Get-MemoryCandidate $file.FullName "Architecture" $false $false))
}
foreach ($file in Get-ChildItem (Join-Path $root ".ai\summaries") -File -Filter "*.md" | Where-Object { $_.Name -notin @("README.md", "_template.md") }) {
    $candidates.Add((Get-MemoryCandidate $file.FullName "Architecture" $false $false))
}
foreach ($file in Get-ChildItem (Join-Path $root ".ai\decision") -File -Filter "????-??-??-*.md") {
    $candidates.Add((Get-MemoryCandidate $file.FullName "Decisions" $false $false))
}

$activePreviousWork = [System.Collections.Generic.List[object]]::new()
foreach ($file in Get-ChildItem $tasksPath -File -Filter "????-??-??-*.md" | Where-Object { $_.FullName -ne $currentTaskPath }) {
    $candidate = Get-MemoryCandidate $file.FullName "Previous Work" $false $false
    $activePreviousWork.Add($candidate)
    $candidates.Add($candidate)
}

$relevantActiveCount = @($activePreviousWork | Where-Object { $_.Score -ge $minimumScore }).Count
$archiveSearched = $false
$usedArchiveFallback = $false
$shouldSearchArchive = $ArchiveMode -eq "Always" -or ($ArchiveMode -eq "Auto" -and $relevantActiveCount -lt $archiveFallbackMinimum)
if ($shouldSearchArchive) {
    $archiveSearched = $true
    foreach ($file in Get-ChildItem (Join-Path $tasksPath "archive") -File -Filter "????-??-??-*.md") {
        $candidates.Add((Get-MemoryCandidate $file.FullName "Previous Work" $true $false))
        $usedArchiveFallback = $true
    }
}

if ($IncludeCode) {
    $allowedExtensions = @(".lua", ".luau", ".json", ".toml", ".yaml", ".yml", ".md", ".project")
    foreach ($codeRoot in $CodeRoots) {
        $resolvedCodeRoot = Join-Path $root $codeRoot
        if (-not (Test-Path $resolvedCodeRoot)) {
            continue
        }
        foreach ($file in Get-ChildItem $resolvedCodeRoot -Recurse -File | Where-Object { $_.Length -le 524288 -and $_.Extension.ToLowerInvariant() -in $allowedExtensions }) {
            $candidates.Add((Get-CodeCandidate $file.FullName))
        }
    }
}

$selected = [System.Collections.Generic.List[object]]::new()
$remainingGlobal = $TokenLimit
foreach ($category in @("Project", "Architecture", "Decisions", "Previous Work", "Code")) {
    if ($category -eq "Code" -and -not $IncludeCode) {
        continue
    }
    $categoryCandidates = @($candidates | Where-Object { $_.Category -eq $category })
    $categorySelected = Select-Candidates $categoryCandidates ([int]$categoryCaps[$category]) $remainingGlobal
    foreach ($item in $categorySelected) {
        $selected.Add($item)
        $remainingGlobal -= $item.EstimatedTokens
    }
}

$result = [pscustomobject]@{
    Query = $Query
    FormatVersion = 2
    CurrentTask = $currentTaskRelativePath
    TokenLimit = $TokenLimit
    EstimatedTokens = ($selected | Measure-Object EstimatedTokens -Sum).Sum
    RemainingTokens = $remainingGlobal
    ArchiveMode = $ArchiveMode
    ArchiveSearched = $archiveSearched
    ArchiveFallbackUsed = $usedArchiveFallback
    IncludeCode = [bool]$IncludeCode
    IncludeContent = $contentMode
    Selected = @($selected | ForEach-Object {
        $lead = [ordered]@{
            Path = $_.Path
            Title = $_.Title
            Category = $_.Category
            Score = $_.Score
            EstimatedTokens = $_.EstimatedTokens
            Archived = $_.Archived
        }
        if ($contentMode) {
            $lead.Truncated = $_.Truncated
            $lead.Content = $_.Content
        }
        [pscustomobject]$lead
    })
}

if ($Format -eq "Json") {
    Write-Output ($result | ConvertTo-Json -Depth 6 -Compress)
    exit 0
}

Write-Output "# Retrieval Leads"
Write-Output ""
Write-Output "- Current task already loaded: $currentTaskRelativePath"
Write-Output "- Output: $($result.EstimatedTokens) / $TokenLimit estimated tokens; archive searched: $archiveSearched; content included: $contentMode"
Write-Output ""

foreach ($category in @("Project", "Architecture", "Decisions", "Previous Work", "Code")) {
    $items = @($selected | Where-Object { $_.Category -eq $category })
    if ($items.Count -eq 0) {
        continue
    }
    Write-Output "## $category"
    foreach ($item in $items) {
        Write-Output ('- `{0}` - {1} (score {2})' -f $item.Path, $item.Title, $item.Score)
        if ($contentMode) {
            Write-Output ""
            Write-Output '```text'
            Write-Output $item.Content
            Write-Output '```'
        }
    }
    Write-Output ""
}