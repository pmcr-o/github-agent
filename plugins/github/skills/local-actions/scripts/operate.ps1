[CmdletBinding()]
param(
  [ValidateSet('plan','list','run')][string]$Operation='plan',
  [string]$Workspace='.',
  [string]$Workflow='.github/workflows/learn.yml',
  [string]$Job='',
  [string]$Event='workflow_dispatch',
  [switch]$Apply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath $Workspace).Path
if([IO.Path]::IsPathRooted($Workflow)){throw 'Workflow must be workspace-relative'}
if($Workflow -match '(^|[\\/])\.\.([\\/]|$)'){throw 'Workflow may not escape the workspace'}
$workflowPath=[IO.Path]::GetFullPath((Join-Path $root $Workflow))
$prefix=[IO.Path]::GetFullPath($root)
if(-not $prefix.EndsWith([IO.Path]::DirectorySeparatorChar)){$prefix += [IO.Path]::DirectorySeparatorChar}
if(-not $workflowPath.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Workflow escapes workspace'}
$workflowExists=Test-Path -LiteralPath $workflowPath -PathType Leaf
if($Event -notmatch '^[A-Za-z0-9_.:-]+$'){throw 'Event contains unsupported characters'}
if($Job -and $Job -notmatch '^[A-Za-z0-9_.:-]+$'){throw 'Job contains unsupported characters'}
$act=Get-Command act -ErrorAction SilentlyContinue
$docker=Get-Command docker -ErrorAction SilentlyContinue
$args=@($Event,'-W',$Workflow)
if($Job){$args += @('-j',$Job)}
$display='act '+(($args | ForEach-Object { if($_ -match '\s'){ '"'+$_+'"' }else{ $_ } }) -join ' ')
$evidence=[ordered]@{
  schema='pmcro.github.local-actions/v1'
  operation=$Operation
  workspace=$root
  workflow=$Workflow
  workflowExists=[bool]$workflowExists
  job=$Job
  event=$Event
  apply=[bool]$Apply
  actPresent=[bool]$act
  dockerCliPresent=[bool]$docker
  command=$display
}
if($Operation -eq 'plan'){
  $evidence.status='PLANNED'
  Write-Output ('dry run: '+$display)
  $evidence | ConvertTo-Json -Depth 8
  return
}
if(-not $workflowExists){throw "Workflow not found: $Workflow"}
if(-not $act){throw 'act is not installed; this capability does not install it implicitly'}
Push-Location $root
try{
  if($Operation -eq 'list'){
    if(-not $Apply){Write-Output ('DRY-RUN act -l -W "'+$Workflow+'"');return}
    & act -l -W $Workflow
    if($LASTEXITCODE -ne 0){throw "act list failed: $LASTEXITCODE"}
    return
  }
  if(-not $Apply){Write-Output ('DRY-RUN '+$display);return}
  if(-not $docker){throw 'docker CLI is not available'}
  $server=''
  try{$server=(& docker version --format '{{.Server.Version}}' 2>$null)}catch{$server=''}
  if(-not $server){throw 'Docker daemon is not ready; actual local Actions execution requires a running compatible container backend'}
  $previousErrorAction=$ErrorActionPreference
  $ErrorActionPreference='Continue'
  try {
    $runOutput=@(& act @args 2>&1 | ForEach-Object { [string]$_ })
    $code=$LASTEXITCODE
  } finally {
    $ErrorActionPreference=$previousErrorAction
  }
  $evidence.status=if($code -eq 0){'PASS'}else{'FAIL'}
  $evidence.exitCode=$code
  $evidence.dockerServer=[string]$server
  $evidence.output=$runOutput
  if($code -ne 0){throw ("act job failed: $code`n"+($runOutput -join "`n"))}
  $evidence | ConvertTo-Json -Depth 12
} finally {Pop-Location}
