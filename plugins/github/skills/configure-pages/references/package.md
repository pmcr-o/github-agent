# configure-pages

Registered route after independent promotion: `@github-agent /github:configure-pages`.

The operation targets the GitHub Pages REST endpoint for one repository. `workflow` selects custom GitHub Actions deployment; `legacy` selects a branch source. GitHub requires repository permission to manage Pages settings. Fine-grained/GitHub App access requires Pages write plus Administration write for site creation/update.

Dry-run is the default and never mutates the remote repository. Apply uses the caller's existing authenticated `gh` session and does not discover or print credentials.
