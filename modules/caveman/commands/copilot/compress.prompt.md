---
mode: 'agent'
description: 'Caveman: compress a Markdown file in place using understudy-compress (preserves code/paths/URLs, creates a .original.md backup).'
__caveman: true
---

<!-- caveman:command — managed by modules/caveman/bin/install-commands -->

Run the caveman compressor on the file the user names in this prompt.

Steps:

1. Ask the user for the target path if they did not provide one.
2. Verify the path exists and is a regular file inside the current
   workspace.
3. Run `modules/caveman/bin/understudy-compress <path>` from the project
   root (fall back to `scripts/understudy-compress` for legacy layouts).
4. Report bytes / words / tokens before and after, the backup location
   (`<path>.original.md`), and how to undo
   (`@workspace /restore <path>` or
   `understudy-compress --restore <path>`).
5. Do **not** stage or commit. The user will review the diff.

Safety reminders for the caveman compressor:

- Refuses to operate on files outside the current working directory, on
  `.env*` / secret-named files, on symlinks, and on content matching
  common credential patterns (RSA / OpenSSH / AWS keys).
- Always creates a byte-identical backup at `<file>.original.md`.
- `--dry-run` previews savings without modifying the file.
