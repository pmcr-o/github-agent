---
name: configure-pages
description: "Inspect and configure GitHub Pages for one repository through the GitHub Pages REST API; dry-run by default and remote mutation only with explicit Apply."
---
# configure-pages

Route: `@github-agent /github:configure-pages`.

## Contract
1. Use `scripts/operate.ps1` for both agent and manual execution.
2. Dry-run is the default. It may inspect the current Pages state but performs no remote mutation.
3. `-Apply` is required to create or update the Pages site.
4. `workflow` configures Pages for a custom GitHub Actions deployment workflow. `legacy` configures a branch source (`/` or `/docs`).
5. Apply uses the already-authenticated `gh` identity. The skill never searches for or prints credentials.
6. The authenticated identity must already have repository permission to manage Pages settings.
7. Emit the desired state, observed state, API operation, and verified final state as evidence.

## Template use
A repository template may ship `.github/workflows/pages.yml`. A newly created repository still needs Pages enabled/configured; this capability is the registered GitHub-domain path for doing that when authority is available.
