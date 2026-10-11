---
name: template-marketplace-bootstrap
description: "Generate a customer-owned GitHub template bootstrap workflow and local PMCR-O marketplace provisioning script; dry-run by default, no remote mutation, and compatible with optional GitHub App repository dispatch."
---
# template-marketplace-bootstrap

Route: `@github-agent /github:template-marketplace-bootstrap`.

## Contract
1. Use `scripts/operate.ps1` for both agent and manual terminal execution.
2. Dry-run is the default and creates no files. `-Apply` writes only four managed bootstrap files.
3. Never creates a repository, pushes a branch, opens a PR, installs runtimes, or calls a billing service itself.
4. The generated workflow supports `workflow_dispatch` and optional `repository_dispatch`, so a GitHub App may trigger it later without becoming the PMCR-O authority.
5. The generated repository remains customer-owned. PMCR-O integration happens through the checked `pmcro-project:integrate-project` entrypoint from the selected PMCR-O source ref.
6. Local/self-hosted execution is explicitly unmetered by this skill. Any paid Tooensure service must meter only the managed resources it actually supplies.
7. Existing managed bootstrap paths are conflicts and are never overwritten implicitly.

## Product boundary
This skill is the GitHub transport/bootstrap surface for a dual-mode product: self-hosted/local PMCR-O remains usable without Tooensure Cloud, while an optional hosted service may provide managed runners/models, retained registries, federation/eval capacity, governance/team controls, and support.
