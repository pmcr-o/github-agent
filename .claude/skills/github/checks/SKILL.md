---
name: checks
description: Show GitHub CLI authentication status without changing credentials. Use when the spoken call is @orchestrator /github:checks. Do not use to push, merge, or delete.
license: MIT
---

# checks

Spoken call: `@orchestrator /github:checks`.

Run `scripts/operate.ps1`.

```powershell
pwsh -NoProfile -File scripts/operate.ps1
pwsh -NoProfile -File scripts/operate.ps1 -Execute
```

## When to Use

- Show GitHub CLI authentication status without changing credentials.

## When Not to Use

- Push, force-push, merge, or delete

## Inputs

| Input | Required | Description |
| --- | --- | --- |
| Execute | No | Run the read-only gh command. Absent, the script prints a dry run |

## Workflow

1. Run the dry run.
2. Pass `-Execute` only for the read-only command `gh auth status`.

## Validation

- [ ] The dry run exits 0

## Common Pitfalls

| Pitfall | Solution |
| --- | --- |
| Installing gh from this skill | Record the gap. Do not install |
