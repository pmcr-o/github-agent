param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$skill=Split-Path -Parent $PSScriptRoot
foreach($rel in @('SKILL.md','agents','scripts','references','assets','tests')){if(-not(Test-Path -LiteralPath (Join-Path $skill $rel))){throw "missing $rel"}}
$ws=Join-Path $skill 'tests\workspace'
$op=Join-Path $skill 'scripts\operate.ps1'
$plan=& $op -Operation plan -Workspace $ws -Workflow '.github/workflows/test.yml'
if(($plan|Out-String) -notmatch '"status"\s*:\s*"PLANNED"'){throw 'plan evidence missing'}
$dry=& $op -Operation run -Workspace $ws -Workflow '.github/workflows/test.yml' -Job smoke
if(($dry|Out-String) -notmatch 'DRY-RUN act workflow_dispatch'){throw 'run must dry-run by default'}
$escaped=$false
try{& $op -Operation plan -Workspace $ws -Workflow '..\outside.yml' | Out-Null}catch{$escaped=$true}
if(-not $escaped){throw 'path escape was not refused'}
'PASS'
