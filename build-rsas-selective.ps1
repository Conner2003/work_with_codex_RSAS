param(
    [string]$RSASRoot = "",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Project = Join-Path $RepoRoot "renderdoccmd\renderdoccmd.vcxproj"
$OutDir = Join-Path $RepoRoot "x64\Release"
$BuildOut = Join-Path $RepoRoot "rsas-build-output"

function Find-MSBuild {
    $cmd = Get-Command msbuild.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $found = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\MSBuild.exe" | Select-Object -First 1
        if ($found) { return $found }
    }
    throw "MSBuild.exe not found. Install Visual Studio 2022 / Build Tools with Desktop development with C++ and a Windows SDK."
}

$msbuild = Find-MSBuild
Write-Host "MSBuild: $msbuild"
Write-Host "Source:  $RepoRoot"

if ($Clean) {
    & $msbuild $Project /t:Clean /m /p:Configuration=Release /p:Platform=x64
    if ($LASTEXITCODE -ne 0) { throw "RenderDoc clean failed with exit code $LASTEXITCODE" }
}

& $msbuild $Project /m /p:Configuration=Release /p:Platform=x64 /verbosity:minimal
if ($LASTEXITCODE -ne 0) { throw "RenderDoc x64 Release build failed with exit code $LASTEXITCODE" }

$cmdExe = Join-Path $OutDir "renderdoccmd.exe"
$rdocDll = Join-Path $OutDir "renderdoc.dll"
if (!(Test-Path $cmdExe)) { throw "Missing build output: $cmdExe" }
if (!(Test-Path $rdocDll)) { throw "Missing build output: $rdocDll" }

$probe = (& $cmdExe rsas-selective-replay --probe 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $probe -notmatch "RSAS_SELECTIVE_REPLAY_V1") {
    throw "Built renderdoccmd.exe does not expose the RSAS selective replay extension. Probe output: $probe"
}
Write-Host "Probe PASS: RSAS_SELECTIVE_REPLAY_V1"

New-Item -ItemType Directory -Path $BuildOut -Force | Out-Null
Copy-Item $cmdExe (Join-Path $BuildOut "renderdoccmd.exe") -Force
Copy-Item $rdocDll (Join-Path $BuildOut "renderdoc.dll") -Force
Set-Content -Path (Join-Path $BuildOut "PROBE.txt") -Value $probe -Encoding ASCII

if ($RSASRoot) {
    $dest = Join-Path $RSASRoot "tools\renderdoc\1.46\x64"
    if (!(Test-Path $dest)) { throw "RSAS RenderDoc runtime directory not found: $dest" }
    Copy-Item $cmdExe (Join-Path $dest "renderdoccmd.exe") -Force
    Copy-Item $rdocDll (Join-Path $dest "renderdoc.dll") -Force
    $installedProbe = (& (Join-Path $dest "renderdoccmd.exe") rsas-selective-replay --probe 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $installedProbe -notmatch "RSAS_SELECTIVE_REPLAY_V1") {
        throw "RSAS-installed renderdoccmd probe failed: $installedProbe"
    }
    Write-Host "Installed custom RenderDoc into: $dest"
}

$zip = Join-Path $RepoRoot "RenderDoc-1.46-RSAS-Selective-x64.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $BuildOut "renderdoccmd.exe"),(Join-Path $BuildOut "renderdoc.dll"),(Join-Path $BuildOut "PROBE.txt") -DestinationPath $zip -CompressionLevel Optimal

Write-Host ""
Write-Host "BUILD PASS"
Write-Host "Output: $BuildOut"
Write-Host "Upload/copy this ZIP if needed: $zip"
