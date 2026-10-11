# validate.ps1 - standalone skill structure and agent-convention validation; no provider or network calls.
[CmdletBinding()]
param([string]$SkillRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($SkillRoot)) { $SkillRoot = Split-Path -Parent $PSScriptRoot }

$structureSkillDir = [System.IO.Path]::GetFullPath($SkillRoot)
$structureSkillName = Split-Path -Leaf $structureSkillDir
$structureFailures = New-Object System.Collections.Generic.List[string]
foreach ($structureFolder in @('scripts', 'references', 'assets', 'agents')) {
    $structurePath = Join-Path $structureSkillDir $structureFolder
    if (-not (Test-Path -LiteralPath $structurePath -PathType Container)) {
        $structureFailures.Add("$structureFolder/ missing")
    } elseif (@(Get-ChildItem -LiteralPath $structurePath -Recurse -File -Force).Count -lt 1) {
        $structureFailures.Add("$structureFolder/ contains no files")
    }
}
$structureEntry = Join-Path $structureSkillDir 'SKILL.md'
if (-not (Test-Path -LiteralPath $structureEntry -PathType Leaf)) {
    $structureFailures.Add('SKILL.md missing')
} else {
    $structureText = [System.IO.File]::ReadAllText($structureEntry)
    $structureFrontmatter = [regex]::Match($structureText, '(?s)\A---\r?\n(.*?)\r?\n---(?:\r?\n|$)')
    if (-not $structureFrontmatter.Success) {
        $structureFailures.Add('SKILL.md frontmatter missing')
    } else {
        $structureName = [regex]::Match($structureFrontmatter.Groups[1].Value, '(?m)^name:[ \t]*([a-z0-9]+(?:-[a-z0-9]+)*)[ \t]*\r?$')
        if (-not $structureName.Success -or $structureName.Groups[1].Value -ne $structureSkillName -or $structureSkillName.Length -gt 64) {
            $structureFailures.Add('Frontmatter name must match the skill directory and naming rules')
        }
        $structureDescription = [regex]::Match($structureFrontmatter.Groups[1].Value, '(?m)^description:[ \t]*(.*?)\r?$').Groups[1].Value.Trim()
        if ($structureDescription.Length -ge 2 -and $structureDescription.StartsWith('"') -and $structureDescription.EndsWith('"')) {
            $structureDescription = $structureDescription.Substring(1, $structureDescription.Length - 2)
        }
        if ([string]::IsNullOrWhiteSpace($structureDescription) -or $structureDescription.Length -gt 1024) {
            $structureFailures.Add('Description must contain 1 to 1024 characters')
        }
    }
    $structureLines = [System.IO.File]::ReadAllLines($structureEntry).Length
    if ($structureLines -gt 150) { $structureFailures.Add("SKILL.md is $structureLines lines; budget is 150") }
}
$structureAgentDir = Join-Path $structureSkillDir 'agents'
$structureHasDefinition = $false
if (Test-Path -LiteralPath $structureAgentDir -PathType Container) {
    foreach ($structureAgentFile in @(Get-ChildItem -LiteralPath $structureAgentDir -Recurse -File -Force)) {
        if ($structureAgentFile.Name -notin @('openai.yaml', 'openai.yml') -and -not $structureAgentFile.Name.EndsWith('.agent.md', [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        $structureAgentText = [System.IO.File]::ReadAllText($structureAgentFile.FullName)
        if ([string]::IsNullOrWhiteSpace($structureAgentText)) { continue }
        if ($structureAgentFile.Name -in @('openai.yaml', 'openai.yml')) {
            # Validate this marketplace's quoted UI-metadata contract; this is not a general YAML parser.
            $structureInterface = [regex]::Match($structureAgentText, '(?m)^interface:[ \t]*\r?$')
            $structureAgentValid = $structureInterface.Success
            $structureFields = @{}
            foreach ($structureField in @('display_name', 'short_description', 'default_prompt')) {
                $structureFieldMatches = [regex]::Matches($structureAgentText, ('(?m)^  ' + $structureField + ':[ \t]*"([^"\r\n]+)"[ \t]*\r?$'))
                if ($structureFieldMatches.Count -ne 1 -or [string]::IsNullOrWhiteSpace($structureFieldMatches[0].Groups[1].Value)) {
                    $structureAgentValid = $false
                } else {
                    $structureFields[$structureField] = $structureFieldMatches[0].Groups[1].Value
                }
            }
            if ($structureAgentValid) {
                $structureAgentValid = $structureFields.short_description.Length -ge 25 -and $structureFields.short_description.Length -le 64
                $structureAgentValid = $structureAgentValid -and $structureFields.default_prompt.Contains('$' + $structureSkillName)
            }
            if ($structureAgentValid) { $structureHasDefinition = $true }
        } elseif ($structureAgentFile.Name.EndsWith('.agent.md', [System.StringComparison]::OrdinalIgnoreCase)) {
            $structureAgentFrontmatter = [regex]::Match($structureAgentText, '(?s)\A---\r?\n(.*?)\r?\n---\r?\n(.+)')
            if ($structureAgentFrontmatter.Success -and
                $structureAgentFrontmatter.Groups[1].Value -match '(?m)^description:[ \t]*\S.+' -and
                $structureAgentFrontmatter.Groups[2].Value.Trim().Length -ge 10) {
                $structureHasDefinition = $true
            }
        }
    }
}
if (-not $structureHasDefinition) {
    $structureFailures.Add('agents/ must contain nonempty openai.yaml UI metadata or a described .agent.md with instructions; placeholders do not count')
}
if ($structureFailures.Count -gt 0) {
    foreach ($structureFailure in $structureFailures) { [Console]::Error.WriteLine("FAIL $($structureSkillName): $structureFailure") }
    exit 1
}
Write-Output "OK skill structure and agent definition: $structureSkillName"
exit 0
