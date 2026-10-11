# Local GitHub Actions runtime

This capability uses `act` as the local GitHub Actions runner. Actual job execution also requires a compatible running container backend such as Docker Desktop.

`act` and Docker are runtime dependencies, not authority. Their presence does not grant publication, repository write, secret access, or network permission.

The PMCR-O route is `@github-agent /github:local-actions`. Agent and manual terminal execution use the same `scripts/operate.ps1` entrypoint.
