[CmdletBinding()]
param(
  [string]$Workspace='.',
  [ValidateSet('generic','maui')][string]$TemplateKind='generic',
  [string]$PmcroRepository='pmcr-o/pmcro-agent',
  [string]$PmcroRef='main',
  [ValidateSet('pull-request','artifact')][string]$Delivery='pull-request',
  [switch]$Apply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath $Workspace).Path
if($PmcroRepository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'){throw 'PmcroRepository must be owner/repository'}
if([string]::IsNullOrWhiteSpace($PmcroRef) -or $PmcroRef -match '[\r\n]'){throw 'PmcroRef is required'}
$configPath=Join-Path $root 'pmcro.template.json'
$workflowPath=Join-Path $root '.github/workflows/pmcro-marketplace-bootstrap.yml'
$bootstrapPath=Join-Path $root 'eng/pmcro/bootstrap-marketplace.ps1'
$verifyPath=Join-Path $root 'eng/pmcro/verify-bootstrap.ps1'
$managed=@($configPath,$workflowPath,$bootstrapPath,$verifyPath)
$conflicts=@($managed|Where-Object{Test-Path -LiteralPath $_})
$plan=[ordered]@{schema='pmcro.github.template-bootstrap-plan/v1';workspace=$root;templateKind=$TemplateKind;pmcroRepository=$PmcroRepository;pmcroRef=$PmcroRef;delivery=$Delivery;apply=[bool]$Apply;managedFiles=@($managed|ForEach-Object{[IO.Path]::GetRelativePath($root,$_).Replace('\','/')});conflicts=@($conflicts|ForEach-Object{[IO.Path]::GetRelativePath($root,$_).Replace('\','/')});remoteMutation=$false;localExecutionUnmetered=$true;managedServiceRequired=$false}
if($conflicts.Count -gt 0){$plan|ConvertTo-Json -Depth 8;throw 'managed bootstrap path already exists; reconcile explicitly before apply'}
if(-not $Apply){Write-Output ('dry run: generate '+($plan.managedFiles -join ', '));$plan|ConvertTo-Json -Depth 8;return}
$config=[ordered]@{schema='pmcro.template-product/v1';templateKind=$TemplateKind;pmcroRepository=$PmcroRepository;pmcroRef=$PmcroRef;delivery=$Delivery;localExecutionUnmetered=$true;managedServiceRequired=$false;githubAppDispatchOptional=$true;marketplaceGeneration='customer-owned';hostedMeteringRule='meter only Tooensure-hosted services; never meter local/self-hosted PMCR-O execution'}|ConvertTo-Json -Depth 8
$bootstrap=@'
[CmdletBinding()]
param([string]$Workspace='.',[Parameter(Mandatory=$true)][string]$Source,[switch]$Apply)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath $Workspace).Path;$source=(Resolve-Path -LiteralPath $Source).Path
$meta=Join-Path $source '.pmcro/control/project.json';if(-not(Test-Path -LiteralPath $meta -PathType Leaf)){throw 'PMCR-O source project metadata missing'}
$m=Get-Content -LiteralPath $meta -Raw|ConvertFrom-Json;if([string]$m.id -ne 'pmcro-agent'){throw 'Source must be pmcro-agent'}
$integrate=Join-Path $source 'plugins/pmcro-project/skills/integrate-project/scripts/integrate.py';if(-not(Test-Path -LiteralPath $integrate -PathType Leaf)){throw 'integrate-project entrypoint missing'}
$python=Get-Command python -ErrorAction SilentlyContinue;if(-not $python){throw 'python runtime not installed; bootstrap does not install runtimes'}
$args=@($integrate,'--target',$root,'--source',$source);if($Apply){$args+='--apply'}
$display='python "'+$integrate+'" --target "'+$root+'" --source "'+$source+'"'+$(if($Apply){' --apply'}else{''})
if(-not $Apply){Write-Output ('dry run: '+$display);return}
& $python.Source @args
if($LASTEXITCODE -ne 0){throw "PMCR-O integration failed: $LASTEXITCODE"}
return
'@
$verify=@'
[CmdletBinding()]param([string]$Workspace='.')
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop';$root=(Resolve-Path -LiteralPath $Workspace).Path
foreach($rel in @('.pmcro/control/project.json','.agents/catalog.json','.agents/routing.json','.github/README.md')){if(-not(Test-Path -LiteralPath (Join-Path $root $rel))){throw "bootstrap validation missing $rel"}}
$p=Get-Content -LiteralPath (Join-Path $root '.pmcro/control/project.json') -Raw|ConvertFrom-Json;if(-not $p.integrated){throw 'project is not marked integrated'}
'PASS';return
'@
$workflow=@"
name: PMCR-O Marketplace Bootstrap
on:
  workflow_dispatch:
  repository_dispatch:
    types: [pmcro.bootstrap]
permissions:
  contents: write
  pull-requests: write
jobs:
  bootstrap:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout customer repository
        uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - name: Checkout validated PMCR-O source
        uses: actions/checkout@v6
        with:
          repository: $PmcroRepository
          ref: $PmcroRef
          path: .pmcro-bootstrap/pmcro-agent
      - name: Generate marketplace
        shell: pwsh
        run: ./eng/pmcro/bootstrap-marketplace.ps1 -Workspace . -Source ./.pmcro-bootstrap/pmcro-agent -Apply
      - name: Verify generated control plane
        shell: pwsh
        run: ./eng/pmcro/verify-bootstrap.ps1 -Workspace .
"@
if($Delivery -eq 'pull-request'){$workflow+=@'
      - name: Open bootstrap pull request
        shell: bash
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          rm -rf .pmcro-bootstrap
          if git diff --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then exit 0; fi
          branch="pmcro/bootstrap-${GITHUB_RUN_ID}"
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git checkout -b "$branch"
          git add .pmcro .agents .claude .grok .cursor .github plugins dotagents.manifest.json
          git commit -m "chore: integrate PMCR-O marketplace"
          git push origin "$branch"
          gh pr create --title "Integrate PMCR-O marketplace" --body "Generated by the repository-owned PMCR-O bootstrap workflow." --head "$branch"
'@}else{$workflow+=@'
      - name: Package generated marketplace
        shell: pwsh
        run: Remove-Item -Recurse -Force .pmcro-bootstrap
      - name: Upload marketplace artifact
        uses: actions/upload-artifact@v4
        with:
          name: pmcro-generated-marketplace
          include-hidden-files: true
          path: |
            .pmcro
            .agents
            .claude
            .grok
            .cursor
            .github
            plugins
            dotagents.manifest.json
'@}
foreach($p in @($configPath,$workflowPath,$bootstrapPath,$verifyPath)){New-Item -ItemType Directory -Force -Path (Split-Path -Parent $p)|Out-Null}
[IO.File]::WriteAllText($configPath,$config+[Environment]::NewLine,[Text.UTF8Encoding]::new($false));[IO.File]::WriteAllText($workflowPath,$workflow+[Environment]::NewLine,[Text.UTF8Encoding]::new($false));[IO.File]::WriteAllText($bootstrapPath,$bootstrap+[Environment]::NewLine,[Text.UTF8Encoding]::new($false));[IO.File]::WriteAllText($verifyPath,$verify+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
$plan.status='PASS';$plan|ConvertTo-Json -Depth 8
return
