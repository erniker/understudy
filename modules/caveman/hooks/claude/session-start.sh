#!/usr/bin/env bash
# Claude Code SessionStart hook for caveman mode.
#
# Output of this script is injected by Claude Code into the session as
# additional context, so we use it to remind the model that the user is
# working in caveman mode and the terse-style rules still apply.
#
# Installed by:  modules/caveman/bin/install-hooks install --mode remind
# Removed by:    modules/caveman/bin/install-hooks uninstall
#
# Safe-by-default: this hook never modifies any file in the repository.

set -euo pipefail

cat <<'CAVEMAN_REMIND_EOF'
[caveman:active] Session resumed in caveman mode.

Operating contract for this session:
- Drop filler words ("just", "really", "simply", "actually").
- Prefer code blocks and tables over prose.
- One-sentence answers when the question allows it.
- Keep explanations to bullet lists; expand only when explicitly asked.
- Do not repeat the user's question back before answering.

Style scope: communication only. Code, identifiers and inline strings
keep their normal spelling.
CAVEMAN_REMIND_EOF
