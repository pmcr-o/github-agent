# operate.ps1 — dry run by default. -Execute runs one read-only gh command. Does not install gh.
[CmdletBinding()]
param([switch]$Execute)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$command = 'workflow list --limit 1'
if (-not $Execute) {
    Write-Output ("dry run: gh " + $command)
    exit 0
}
$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    [Console]::Error.WriteLine('gh is not on PATH. This script does not install it.')
    exit 1
}
& gh @($command -split ' ')
exit $LASTEXITCODE
