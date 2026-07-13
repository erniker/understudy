# 📚 Understudy Documentation

Welcome to the Understudy docs. This section is organized so it can be
published as a static site (Docusaurus, MkDocs, VitePress, etc.) without
restructuring.

## Index

1. [Introduction and Core Concepts](01-introduction.md)
2. [Quick Start](02-quick-start.md)
3. [Platform Capability Matrix](03-platform-comparison.md)
4. [Guardrails](04-guardrails.md)
5. [Roles & Spec-Driven Development](05-roles-and-workflow.md)
6. Platforms
   - [GitHub Copilot CLI](platforms/copilot-cli.md)
   - [VS Code Copilot](platforms/vscode-copilot.md)
   - [Claude Code](platforms/claude-code.md)
   - [Cursor](platforms/cursor.md)
7. [Cross-Platform Workflows](08-cross-platform-workflows.md)
8. [Configuration Reference (`understudy.yaml`)](09-configuration.md)
   - [Local-only mode](09-configuration.md#local-only-mode) — keep AI config out of git
   - [Module system](09-configuration.md#module-system) — opt-in modules like caveman
9. [Caveman Mode (token-efficient role + compress script)](10-caveman-mode.md)
   - [Evals harness](../modules/caveman/evals/README.md) — reproducible token-reduction numbers
10. [Troubleshooting and FAQ](11-troubleshooting.md)
11. [Global Mode — machine-wide install (`--global`)](12-global-mode.md)

### 📖 Tutorials (hands-on walkthroughs)

- [Tutorials index](tutorials/README.md)
  - [GitHub Copilot CLI tutorial](tutorials/copilot-cli-tutorial.md)
  - [VS Code Copilot tutorial](tutorials/vscode-copilot-tutorial.md)
  - [Claude Code tutorial](tutorials/claude-code-tutorial.md)
  - [Cursor tutorial](tutorials/cursor-tutorial.md)

> File names use numeric prefixes for stable ordering. The gap at 06-07 is
> reserved for future chapters; the index above is the recommended reading
> order.

## How to read this

- First time here? Read [Introduction](01-introduction.md) → [Quick Start](02-quick-start.md).
- Looking for a feature on your tool? Jump to the platform page.
- Want a guided walkthrough? Start with the [tutorials](tutorials/README.md).
- Comparing tools? See the [capability matrix](03-platform-comparison.md).

## Related

- [Main README](../README.md)
- [Contributing guide](../CONTRIBUTING.md)
- [Security policy](../SECURITY.md)
- [Changelog](../CHANGELOG.md)
