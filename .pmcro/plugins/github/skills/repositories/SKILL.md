---
name: repositories
description: List repositories the signed-in account can see. Use when the spoken call is @orchestrator /github:repositories. Do not use to push, merge, or delete.
license: MIT
---

# repositories

Spoken call: `@orchestrator /github:repositories`.

Run `scripts/operate.ps1`.

```powershell
pwsh -NoProfile -File scripts/operate.ps1
pwsh -NoProfile -File scripts/operate.ps1 -Execute
```

## When to Use

- List repositories the signed-in account can see.

## When Not to Use

- Push, force-push, merge, or delete

## Inputs

| Input | Required | Description |
| --- | --- | --- |
| Execute | No | Run the read-only gh command. Absent, the script prints a dry run |

## Workflow

1. Run the dry run.
2. Pass `-Execute` only for the read-only command `gh repo list --limit 1`.

## Validation

- [ ] The dry run exits 0

## Common Pitfalls

| Pitfall | Solution |
| --- | --- |
| Installing gh from this skill | Record the gap. Do not install |
