[CmdletBinding()]
param(
	[Parameter(Position = 0)]
	[string]$ProjectPath,

	[Parameter(Position = 1)]
	[ValidateSet("luau", "extension", "complete", "test")]
	[string]$Operation,

	[Parameter(Position = 2)]
	[string]$Platform
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$manifestReader = Join-Path $PSScriptRoot "readBuildManifest.luau"
$buildRoot = Join-Path $repositoryRoot "build"
$vsce = Join-Path $repositoryRoot "node_modules\.bin\vsce.cmd"

function Invoke-External([string]$Description, [scriptblock]$Command) {
	& $Command
	if ($LASTEXITCODE -ne 0) {
		throw "$Description failed with exit code $LASTEXITCODE."
	}
}

function Get-RepositoryRelativePath([string]$Path) {
	$resolvedRepositoryRoot = (Resolve-Path -LiteralPath $repositoryRoot).Path.TrimEnd([char[]]@('\', '/'))
	$resolvedPath = (Resolve-Path -LiteralPath $Path).Path
	if (-not $resolvedPath.StartsWith($resolvedRepositoryRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
		throw "Build project must be inside the repository: $Path"
	}
	return $resolvedPath.Substring($resolvedRepositoryRoot.Length + 1).Replace("/", "\\")
}

function ConvertTo-StringArray($Value, [string]$FieldName, [string]$ManifestPath) {
	if ($null -eq $Value -or $Value -is [PSCustomObject]) {
		return @()
	}
	$result = @($Value)
	foreach ($item in $result) {
		if ($item -isnot [string]) {
			throw "Build manifest field '$FieldName' must contain strings: $ManifestPath"
		}
	}
	return $result
}

function Test-IgnoredBuildPath([string]$Path) {
	return $Path -match "(^|[\\/])(\.git|node_modules|build)([\\/]|$)"
}

function Get-BuildManifestPaths([string]$RequestedPath) {
	$resolvedPath = if ([string]::IsNullOrWhiteSpace($RequestedPath)) {
		$repositoryRoot
	} elseif ([System.IO.Path]::IsPathRooted($RequestedPath)) {
		(Resolve-Path -LiteralPath $RequestedPath).Path
	} else {
		(Resolve-Path -LiteralPath (Join-Path $repositoryRoot $RequestedPath)).Path
	}

	if (Test-Path -LiteralPath $resolvedPath -PathType Leaf) {
		if ((Split-Path -Leaf $resolvedPath) -ne "build.luau") {
			throw "Expected a project directory or build.luau manifest, received: $resolvedPath"
		}
		return @($resolvedPath)
	}

	$directManifest = Join-Path $resolvedPath "build.luau"
	if (Test-Path -LiteralPath $directManifest -PathType Leaf) {
		return @($directManifest)
	}

	$manifests = @(
		Get-ChildItem -LiteralPath $resolvedPath -Recurse -File -Filter "build.luau" |
			Where-Object { -not (Test-IgnoredBuildPath $_.FullName) } |
			Sort-Object FullName |
			Select-Object -ExpandProperty FullName
	)
	if ($manifests.Count -eq 0) {
		throw "No build.luau manifests were found below: $resolvedPath"
	}
	return $manifests
}

function Get-BuildProject([string]$ManifestPath) {
	$json = & lune run $manifestReader $ManifestPath
	if ($LASTEXITCODE -ne 0) {
		throw "Could not read build manifest: $ManifestPath"
	}

	try {
		$metadata = $json | ConvertFrom-Json -ErrorAction Stop
	} catch {
		throw "Build manifest reader returned invalid JSON for ${ManifestPath}: $($_.Exception.Message)"
	}

	$projectRoot = Split-Path -Parent $ManifestPath
	return [PSCustomObject]@{
		ManifestPath = $ManifestPath
		Root = $projectRoot
		RelativeRoot = Get-RepositoryRelativePath $projectRoot
		Entries = [string[]]@(ConvertTo-StringArray $metadata.entries "entries" $ManifestPath)
		Extensions = [string[]]@(ConvertTo-StringArray $metadata.extensions "extensions" $ManifestPath)
		Platforms = [string[]]@(ConvertTo-StringArray $metadata.platforms "platforms" $ManifestPath)
	}
}

function Select-MenuItem([string]$Prompt, [object[]]$Items, [scriptblock]$Display) {
	if ($Items.Count -eq 1) {
		return $Items[0]
	}

	Write-Host $Prompt
	for ($index = 0; $index -lt $Items.Count; $index += 1) {
		Write-Host ("[{0}] {1}" -f ($index + 1), (& $Display $Items[$index]))
	}
	while ($true) {
		$selection = Read-Host "Selection"
		$number = 0
		if ([int]::TryParse($selection, [ref]$number) -and $number -ge 1 -and $number -le $Items.Count) {
			return $Items[$number - 1]
		}
		Write-Host "Enter a number from 1 to $($Items.Count)." -ForegroundColor Yellow
	}
}

function Get-SelectedProjects([string]$RequestedPath) {
	$projects = @(Get-BuildManifestPaths $RequestedPath | ForEach-Object { Get-BuildProject $_ })
	if (-not [string]::IsNullOrWhiteSpace($RequestedPath) -or $projects.Count -eq 1) {
		return $projects
	}

	$allProjects = [PSCustomObject]@{ RelativeRoot = "All discovered projects"; IsAll = $true }
	$selection = Select-MenuItem "Select project:" @($projects + $allProjects) { param($item) $item.RelativeRoot }
	if ($selection.IsAll) {
		return $projects
	}
	return @($selection)
}

function Get-SelectedOperation([string]$RequestedOperation) {
	if (-not [string]::IsNullOrWhiteSpace($RequestedOperation)) {
		return $RequestedOperation
	}
	return Select-MenuItem "Select operation:" @("luau", "extension", "complete", "test") { param($item) $item }
}

function Get-SelectedPlatform([object[]]$Projects, [string]$RequestedPlatform, [string]$SelectedOperation, [bool]$PromptForPlatform) {
	if (-not [string]::IsNullOrWhiteSpace($RequestedPlatform)) {
		return $RequestedPlatform
	}
	if ($SelectedOperation -eq "extension" -or -not $PromptForPlatform) {
		return $null
	}

	$platforms = @($Projects | ForEach-Object { $_.Platforms } | Sort-Object -Unique)
	if ($platforms.Count -eq 0) {
		return $null
	}
	if ($platforms.Count -eq 1) {
		return $platforms[0]
	}
	$allPlatforms = "__all__"
	$selection = Select-MenuItem "Select platform:" @($platforms + $allPlatforms) {
		param($item)
		if ($item -eq "__all__") { "All supported platforms" } else { $item }
	}
	return if ($selection -eq "__all__") { $null } else { $selection }
}

function Get-ResolvedEntryPath([object]$Project, [string]$Entry) {
	$entryPath = Join-Path $Project.Root $Entry
	if (-not (Test-Path -LiteralPath $entryPath -PathType Leaf)) {
		throw "Manifest entry does not exist: $entryPath"
	}
	if ($entryPath -notmatch "\.lua[u]?$" ) {
		throw "Manifest entry must be a .lua or .luau file: $entryPath"
	}
	return (Resolve-Path -LiteralPath $entryPath).Path
}

function Get-ResolvedLuauPath([object]$Project, [string]$Entry) {
	$entryRelative = $Entry.Replace("/", "\\")
	return Join-Path (Join-Path $buildRoot (Join-Path "luau" $Project.RelativeRoot)) $entryRelative
}

function Get-BinaryPath([object]$Project, [string]$Entry, [string]$TargetPlatform) {
	$entryRelative = $Entry.Replace("/", "\\")
	$extension = if ($TargetPlatform.StartsWith("windows-")) { ".exe" } else { "" }
	$binaryRelative = [System.IO.Path]::ChangeExtension($entryRelative, $extension)
	return Join-Path (Join-Path $buildRoot (Join-Path "bin" (Join-Path $TargetPlatform $Project.RelativeRoot))) $binaryRelative
}

function Invoke-LuauBuild([object[]]$Projects, [string]$RequestedPlatform) {
	foreach ($project in $Projects) {
		if ($project.Entries.Count -eq 0) {
			Write-Host "Skipping $($project.RelativeRoot): no Luau entries declared."
			continue
		}

		$darkluaConfig = Join-Path $project.Root "darklua.json5"
		if (-not (Test-Path -LiteralPath $darkluaConfig -PathType Leaf)) {
			throw "Project with Luau entries must contain darklua.json5: $($project.Root)"
		}
		if (-not [string]::IsNullOrWhiteSpace($RequestedPlatform) -and $project.Platforms.Count -gt 0 -and $project.Platforms -notcontains $RequestedPlatform) {
			throw "Project $($project.RelativeRoot) does not support platform '$RequestedPlatform'. Supported platforms: $($project.Platforms -join ', ')."
		}

		$targetPlatforms = if ([string]::IsNullOrWhiteSpace($RequestedPlatform)) {
			@($project.Platforms)
		} elseif ($project.Platforms -contains $RequestedPlatform) {
			@($RequestedPlatform)
		} else {
			@()
		}

		foreach ($entry in $project.Entries) {
			$entryPath = Get-ResolvedEntryPath $project $entry
			$resolvedEntry = Get-ResolvedLuauPath $project $entry
			New-Item -ItemType Directory -Force -Path (Split-Path -Parent $resolvedEntry) | Out-Null
			Write-Host "Bundling $entryPath -> $resolvedEntry"
			Invoke-External "DarkLua processing for $entryPath" { & darklua process --config $darkluaConfig $entryPath $resolvedEntry }

			foreach ($targetPlatform in $targetPlatforms) {
				$outputExecutable = Get-BinaryPath $project $entry $targetPlatform
				New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outputExecutable) | Out-Null
				Write-Host "Building $resolvedEntry -> $outputExecutable ($targetPlatform)"
				Invoke-External "Lune build for $entryPath ($targetPlatform)" {
					& lune build --target $targetPlatform --output $outputExecutable $resolvedEntry
				}
			}
		}
	}
}

function Get-ExtensionProjects([object[]]$Projects) {
	$extensionProjects = [System.Collections.Generic.List[object]]::new()
	foreach ($project in $Projects) {
		foreach ($extensionDirectory in $project.Extensions) {
			$root = Join-Path $project.Root $extensionDirectory
			if (-not (Test-Path -LiteralPath $root -PathType Container)) {
				throw "Declared extension directory does not exist: $root"
			}
			foreach ($packagePath in Get-ChildItem -LiteralPath $root -Recurse -File -Filter "package.json" | Sort-Object FullName) {
				if (-not (Test-IgnoredBuildPath $packagePath.FullName)) {
					$extensionProjects.Add([PSCustomObject]@{ Parent = $project; Root = $packagePath.Directory.FullName; PackagePath = $packagePath.FullName })
				}
			}
		}
	}
	return @($extensionProjects)
}

function Get-CompiledExtensionDirectory([object]$Extension) {
	$tsconfigPath = Join-Path $Extension.Root "tsconfig.json"
	if (-not (Test-Path -LiteralPath $tsconfigPath -PathType Leaf)) {
		throw "VS Code extension must contain tsconfig.json: $($Extension.Root)"
	}
	$tsconfig = Get-Content -LiteralPath $tsconfigPath -Raw | ConvertFrom-Json
	$relativeOutDirectory = [string]$tsconfig.compilerOptions.outDir
	if ([string]::IsNullOrWhiteSpace($relativeOutDirectory)) {
		throw "VS Code extension tsconfig.json must declare compilerOptions.outDir: $tsconfigPath"
	}
	return [System.IO.Path]::GetFullPath((Join-Path $Extension.Root $relativeOutDirectory))
}

function Get-ExtensionBinaryPaths([object]$Extension) {
	$binaryProjectRoot = Join-Path $buildRoot "bin"
	if (-not (Test-Path -LiteralPath $binaryProjectRoot -PathType Container)) {
		return @()
	}
	$projectRelative = $Extension.Parent.RelativeRoot
	return @(
		Get-ChildItem -LiteralPath $binaryProjectRoot -Recurse -File |
			Where-Object {
				$relative = $_.FullName.Substring($binaryProjectRoot.TrimEnd([char[]]@('\', '/')).Length + 1).Replace("/", "\\")
				$relative -match "^[^\\]+\\$([regex]::Escape($projectRelative))\\"
			} |
			Sort-Object FullName
	)
}

function Invoke-ExtensionBuild([object[]]$Projects) {
	if (-not (Test-Path -LiteralPath $vsce -PathType Leaf)) {
		throw "VS Code extension dependencies are missing. Run npm install from the repository root."
	}

	$extensions = @(Get-ExtensionProjects $Projects)
	foreach ($extension in $extensions) {
		$package = Get-Content -LiteralPath $extension.PackagePath -Raw | ConvertFrom-Json
		$packageName = [string]$package.name
		if ([string]::IsNullOrWhiteSpace($packageName)) {
			throw "Extension package.json must declare name: $($extension.PackagePath)"
		}

		Write-Host "Compiling VS Code extension: $($extension.Root)"
		Push-Location $extension.Root
		try {
			Invoke-External "TypeScript build for $packageName" { & npm run build }
		} finally {
			Pop-Location
		}

		$compiledDirectory = Get-CompiledExtensionDirectory $extension
		$compiledEntry = Join-Path $compiledDirectory "extension.js"
		if (-not (Test-Path -LiteralPath $compiledEntry -PathType Leaf)) {
			throw "Extension compilation did not produce extension.js: $compiledEntry"
		}

		$binaryPaths = @(Get-ExtensionBinaryPaths $extension)
		if ($extension.Parent.Entries.Count -gt 0 -and $binaryPaths.Count -eq 0) {
			throw "No compiled binaries were found for extension project $($extension.Root). Run the complete operation first."
		}

		$outputDirectory = Join-Path $buildRoot "vsix"
		$outputVsix = Join-Path $outputDirectory "$packageName.vsix"
		$stagingDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("bundle-framework-vsix-" + [guid]::NewGuid().ToString("N"))
		New-Item -ItemType Directory -Force -Path $outputDirectory, $stagingDirectory | Out-Null
		try {
			Get-ChildItem -LiteralPath $compiledDirectory -Force | Copy-Item -Destination $stagingDirectory -Recurse -Force
			Copy-Item -LiteralPath $extension.PackagePath -Destination (Join-Path $stagingDirectory "package.json") -Force
			$licensePath = Join-Path $extension.Root "LICENSE"
			if (-not (Test-Path -LiteralPath $licensePath -PathType Leaf)) {
				$licensePath = Join-Path $repositoryRoot "LICENSE"
			}
			Copy-Item -LiteralPath $licensePath -Destination (Join-Path $stagingDirectory "LICENSE") -Force
			if ($binaryPaths.Count -gt 0) {
				$stagingBin = Join-Path $stagingDirectory "bin"
				New-Item -ItemType Directory -Force -Path $stagingBin | Out-Null
				foreach ($binaryPath in $binaryPaths) {
					Copy-Item -LiteralPath $binaryPath.FullName -Destination (Join-Path $stagingBin $binaryPath.Name) -Force
				}
			}

			Write-Host "Packaging VS Code extension: $outputVsix"
			Push-Location $stagingDirectory
			try {
				Invoke-External "VSCE packaging for $packageName" { & $vsce package --no-dependencies --out $outputVsix }
			} finally {
				Pop-Location
			}
		} finally {
			Remove-Item -LiteralPath $stagingDirectory -Recurse -Force -ErrorAction SilentlyContinue
		}
	}
}

function Invoke-ExtensionInstall([object[]]$Projects) {
	$extensions = @(Get-ExtensionProjects $Projects)
	foreach ($extension in $extensions) {
		$package = Get-Content -LiteralPath $extension.PackagePath -Raw | ConvertFrom-Json
		$vsixPath = Join-Path (Join-Path $buildRoot "vsix") ("$($package.name).vsix")
		if (-not (Test-Path -LiteralPath $vsixPath -PathType Leaf)) {
			throw "Expected packaged VSIX is missing: $vsixPath"
		}
		Write-Host "Installing VS Code extension: $vsixPath"
		Invoke-External "VS Code extension installation for $($package.name)" { & code --install-extension $vsixPath --force }
	}
}

$projects = Get-SelectedProjects $ProjectPath
$selectedOperation = Get-SelectedOperation $Operation
$selectedPlatform = Get-SelectedPlatform $projects $Platform $selectedOperation ([string]::IsNullOrWhiteSpace($ProjectPath) -and [string]::IsNullOrWhiteSpace($Operation))

switch ($selectedOperation) {
	"luau" { Invoke-LuauBuild $projects $selectedPlatform }
	"extension" { Invoke-ExtensionBuild $projects }
	"complete" {
		Invoke-LuauBuild $projects $selectedPlatform
		Invoke-ExtensionBuild $projects
	}
	"test" {
		Invoke-LuauBuild $projects $selectedPlatform
		Invoke-ExtensionBuild $projects
		Invoke-ExtensionInstall $projects
	}
}