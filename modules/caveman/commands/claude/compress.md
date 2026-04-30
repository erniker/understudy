---
name: compress
description: "Caveman: compress a Markdown file in place using understudy-compress (preserves code/paths/URLs, creates a .original.md backup)."
__caveman: true
---

<!-- caveman:command — managed by modules/caveman/bin/install-commands -->

Run the caveman compressor on the provided path and report the token / word
savings.

Target file: `$ARGUMENTS`

Steps:

1. Verify the path exists and is a regular file inside the current
   workspace. If not, stop and explain.
2. Run `modules/caveman/bin/understudy-compress "$ARGUMENTS"` from the
   project root (fall back to `scripts/understudy-compress` for legacy
   layouts).
3. Report:
   - bytes / words / tokens before and after,
   - location of the `.original.md` backup,
   - how to restore (`/restore <path>` or `understudy-compress --restore <path>`).
4. Do **not** stage or commit the change. The user will review the diff
   first.

Safety reminders for the caveman compressor:

- Refuses to operate on files outside CWD, on `.env*` / secret-named
  files, on symlinks, and on content matching common credential patterns.
- Always creates a byte-identical backup at `<file>.original.md`.
- `--dry-run` previews savings without modifying the file.
