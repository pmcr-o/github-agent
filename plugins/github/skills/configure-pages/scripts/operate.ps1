[CmdletBinding()]
param(
  [string]$Repository='pmcr-o/pmcro-agent',
  [ValidateSet('workflow','legacy')][string]$BuildType='workflow',
  [string]$Branch='main',
  [ValidateSet('/','/docs')][string]$Path='/docs',
  [switch]$Apply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'){throw 'Repository must be owner/name'}
if([string]::IsNullOrWhiteSpace($Branch) -or $Branch -match '[\r\n]'){throw 'Branch is required'}
$gh=Get-Command gh -ErrorAction SilentlyContinue
$observed=[ordered]@{available=$false;status='NOT-QUERIED';buildType=$null;source=$null;htmlUrl=$null}
if($gh){
  $nativeVar=Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue
  if($nativeVar){$oldNative=$PSNativeCommandUseErrorActionPreference;$PSNativeCommandUseErrorActionPreference=$false}
  try {
    $probeLines=@(& $gh.Source api "repos/$Repository/pages" 2>&1)
    $probeExit=$LASTEXITCODE
  } finally {
    if($nativeVar){$PSNativeCommandUseErrorActionPreference=$oldNative}
  }
  $probeText=($probeLines|ForEach-Object{"$_"}) -join "`n"
  if($probeExit -eq 0){
    $state=$probeText|ConvertFrom-Json
    $observed.available=$true;$observed.status='PRESENT';$observed.buildType=[string]$state.build_type;$observed.source=$state.source;$observed.htmlUrl=[string]$state.html_url
  } elseif($probeText -match '(?i)HTTP 404|Not Found') {
    $observed.status='ABSENT'
  } else {
    $observed.status='UNRESOLVED'
    if($Apply){throw "unable to inspect Pages state: $probeText"}
  }
} else {
  $observed.status='GH-NOT-PRESENT'
}
$desired=[ordered]@{buildType=$BuildType;source=$null}
if($BuildType -eq 'legacy'){$desired.source=[ordered]@{branch=$Branch;path=$Path}}
$method=if($observed.status -eq 'ABSENT'){'POST'}else{'PUT'}
$plan=[ordered]@{
  schema='pmcro.github.configure-pages/v1';repository=$Repository;apply=[bool]$Apply;remoteMutation=[bool]$Apply;requiresManagePagesPermission=$true;endpoint="repos/$Repository/pages";method=$method;desired=$desired;observed=$observed
}
if(-not $Apply){Write-Output ('dry run: '+$method+' '+$plan.endpoint+' build_type='+$BuildType);$plan|ConvertTo-Json -Depth 10;return}
if(-not $gh){throw 'gh CLI is required for Apply; authenticate it before invocation'}
$body=[ordered]@{build_type=$BuildType}
if($BuildType -eq 'legacy'){$body.source=[ordered]@{branch=$Branch;path=$Path}}
$json=$body|ConvertTo-Json -Depth 6 -Compress
$nativeVar=Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue
if($nativeVar){$oldNative=$PSNativeCommandUseErrorActionPreference;$PSNativeCommandUseErrorActionPreference=$false}
try {
  $applyOut=@($json | & $gh.Source api --method $method "repos/$Repository/pages" --input - 2>&1)
  $applyExit=$LASTEXITCODE
} finally {
  if($nativeVar){$PSNativeCommandUseErrorActionPreference=$oldNative}
}
if($applyExit -ne 0){throw "Pages configuration failed: $(($applyOut|ForEach-Object{"$_"}) -join "`n")"}
$verifyRaw=& $gh.Source api "repos/$Repository/pages"
if($LASTEXITCODE -ne 0){throw 'Pages verification read failed'}
$verified=$verifyRaw|ConvertFrom-Json
if([string]$verified.build_type -ne $BuildType){throw "Pages verification mismatch: expected $BuildType got $($verified.build_type)"}
if($BuildType -eq 'legacy'){
  if([string]$verified.source.branch -ne $Branch -or [string]$verified.source.path -ne $Path){throw 'Pages source verification mismatch'}
}
$plan.status='PASS';$plan.verified=[ordered]@{buildType=[string]$verified.build_type;source=$verified.source;htmlUrl=[string]$verified.html_url;status=[string]$verified.status}
$plan|ConvertTo-Json -Depth 10
return
