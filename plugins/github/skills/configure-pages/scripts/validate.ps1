param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$skillDir=Split-Path -Parent $PSScriptRoot
$name=Split-Path -Leaf $skillDir
$text=Get-Content -LiteralPath (Join-Path $skillDir 'SKILL.md') -Raw
if($text -notmatch "(?m)^name: $name\s*$"){throw "name mismatch for $name"}
foreach($rel in @('agents/github-pages-agent.md','scripts/operate.ps1','references/package.md','assets/request.json','tests/fixture.json')){if(-not(Test-Path -LiteralPath (Join-Path $skillDir $rel) -PathType Leaf)){throw "missing $rel"}}
$op=Get-Content -LiteralPath (Join-Path $skillDir 'scripts/operate.ps1') -Raw
foreach($needle in @('[switch]$Apply',"ValidateSet('workflow','legacy')",'gh CLI is required for Apply','remoteMutation')){if(-not $op.Contains($needle)){throw "operate.ps1 missing contract marker: $needle"}}
'PASS'
return
