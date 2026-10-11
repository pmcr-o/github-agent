[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$MessagePath)
Import-Module (Join-Path $PSScriptRoot 'queue.psm1') -Force -DisableNameChecking
$c=Get-QueueConfig;$m=Read-QueueJson $MessagePath;Validate-Message $m $c|Out-Null;Write-Output "VALID $($m.messageId) $($m.contentDigest)";return
