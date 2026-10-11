param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
foreach($rel in @('SKILL.md','agents/agent.json','scripts/operate.ps1','references/product-boundary.md','assets/request.json','tests/fixture.json')){
  if(-not(Test-Path -LiteralPath (Join-Path $root $rel) -PathType Leaf)){throw "missing $rel"}
}
$skill=Get-Content -LiteralPath (Join-Path $root 'SKILL.md') -Raw
if($skill -notmatch '(?m)^name:\s*template-marketplace-bootstrap\s*$'){throw 'frontmatter name mismatch'}
$script=Get-Content -LiteralPath (Join-Path $root 'scripts/operate.ps1') -Raw
foreach($required in @('workflow_dispatch','repository_dispatch','pmcro.template.json','localExecutionUnmetered','managedServiceRequired')){
  if($script -notmatch [regex]::Escape($required)){throw "operate.ps1 missing $required"}
}
'PASS'
return
