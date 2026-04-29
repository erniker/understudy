# Prose fixture

It is important to note that the wizard is just a simple shell script.

Please simply run `wizard.sh --here` to deploy the project.

In order to test compression, we have placed several phrases. Due to the fact
that the script needs to remove fillers, this paragraph is intentionally verbose.

Visit https://example.com/path/to/page for more details about the project, and
note that the file at /etc/passwd should never actually be modified.

Templates use tokens such as {{PROJECT_NAME}} and {{ROLE_DESCRIPTION}} which
must remain untouched in the output.

Versioning follows v1.2.3 and dates like 2026-04-29 must survive compression.

```bash
echo "the a an please simply"
# this fenced block must remain byte-identical
```

<!-- GUARDRAILS_START -->
- Rule one stays.
- Rule two stays.
<!-- GUARDRAILS_END -->

| col-a | col-b |
| ----- | ----- |
| just  | the   |

Just a final note that should be trimmed of fillers.
