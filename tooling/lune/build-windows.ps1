[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$entryPoint = Join-Path $PSScriptRoot "main.luau"
$darkluaConfig = Join-Path $PSScriptRoot "darklua.json5"
$outputDirectory = Join-Path $repositoryRoot "bin"
$resolvedEntryPoint = Join-Path $outputDirectory "lune-main.luau"
$outputExecutable = Join-Path $outputDirectory "lune-main.exe"

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

Push-Location $repositoryRoot
try {
    Write-Host "Bundling $entryPoint -> $resolvedEntryPoint"
    & darklua process --config $darkluaConfig $entryPoint $resolvedEntryPoint
    if ($LASTEXITCODE -ne 0) {
        throw "DarkLua failed with exit code $LASTEXITCODE."
    }

    Write-Host "Building $resolvedEntryPoint -> $outputExecutable"
    & lune build --target windows-x86_64 --output $outputExecutable $resolvedEntryPoint
    if ($LASTEXITCODE -ne 0) {
        throw "Lune failed with exit code $LASTEXITCODE."
    }
} finally {
    Pop-Location
}

Write-Host "Built Windows x64 executable: $outputExecutable"