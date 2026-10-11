# Repository structure

`github-agent` mirrors the durable repository grammar proven by `dotnet/skills` while extending it with PMCR-O authority.

```text
.pmcro/             canonical PMCR-O authority
.agents/            host-neutral projection
.claude-plugin/     Claude marketplace manifest
.config/            repository tooling surface
.cursor-plugin/     Cursor marketplace manifest
.github/            GitHub host/workflow surface
.vscode/            editor surface
agentic-workflows/  workflow surface
docs/               documentation
eng/                repository engineering/validation
plugins/            generated plugin compatibility projection
tests/              repository-level tests
```

Every routable PMCR-O-owned skill extends the upstream progressive-disclosure pattern with populated `SKILL.md`, `agents/`, `scripts/`, `references/`, `assets/`, and `tests/`.
