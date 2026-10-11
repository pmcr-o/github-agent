---
name: local-actions
description: "Inspect and run GitHub Actions workflows locally through act using the same bounded script for agent and manual terminal execution; actual jobs require explicit apply."
---
# local-actions

Route: `@github-agent /github:local-actions`.

## Contract
1. Keep GitHub-specific local workflow mechanics inside `github-agent`.
2. Use `scripts/operate.ps1` for both agent and manual terminal invocation.
3. `plan` and `list` are non-mutating. `run` is dry-run by default; actual execution requires `-Apply`.
4. Confine workflow paths to the declared workspace.
5. Refuse implicit installation of `act`, Docker, or credentials.
6. Return the exact command, runtime readiness, exit code, and PASS/FAIL evidence to PMCR-O.

## Examples

```powershell
pwsh -NoProfile -File scripts/operate.ps1 -Operation plan -Workspace W:\ProjectName -Workflow .github/workflows/learn.yml
pwsh -NoProfile -File scripts/operate.ps1 -Operation list -Workspace W:\ProjectName -Workflow .github/workflows/learn.yml -Apply
pwsh -NoProfile -File scripts/operate.ps1 -Operation run -Workspace W:\ProjectName -Workflow .github/workflows/learn.yml -Job lesson-authority
pwsh -NoProfile -File scripts/operate.ps1 -Operation run -Workspace W:\ProjectName -Workflow .github/workflows/learn.yml -Job lesson-authority -Apply
```
