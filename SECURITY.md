# Security Policy

## Supported Versions

| Version | Active Support |
|---|---|
| `0.1.x` | ✅ Yes |

While the project is at `0.x.y`, only the most recent version receives security patches.
From `1.0.0` onwards we will maintain a more detailed table of supported versions.

## Reporting a Vulnerability

**Do not open a public issue to report security vulnerabilities.**

If you find a security problem (for example: a hook that allows command injection,
insufficient path validation in the wizard, or a template that accidentally exposes
secrets), report it privately:

### Option 1: GitHub Private Security Advisory (recommended)

Use the
[**Report a vulnerability**](https://github.com/erniker/understudy/security/advisories/new)
feature on GitHub. It allows discussing the issue confidentially before public disclosure.

### Option 2: Email

📧 **josepablomedinagrande@hotmail.com**

Include in your report:

- Description of the problem and potential impact
- Steps to reproduce it
- Affected version (`git describe --tags`)
- Any temporary mitigation you have identified

## Response Process

| Timeframe | Action |
|---|---|
| 48 h | Acknowledgment of the report |
| 7 days | Initial assessment and confirmation or dismissal |
| 30 days | Patch published (if the vulnerability is confirmed) |

Once the patch is published, we will coordinate with you on the timing and content of
public disclosure if you wish.

## Scope

This project is a **configuration file generator** for AI tools.
It does not process user data in production, it has no backend or exposed services.

The most relevant vulnerabilities in this context are:

- Command injection in `wizard.sh` through user or project inputs
- Templates that include insecure patterns that propagate to users' projects
- Claude Code hooks that allow unintended arbitrary execution
- Accidental exposure of secrets in generated files

## Responsible Disclosure

We follow a **coordinated disclosure** policy. We ask for a minimum of **30 days** before
any public release to have time to prepare and distribute the patch.

We appreciate those who contribute to the security of the project responsibly.
