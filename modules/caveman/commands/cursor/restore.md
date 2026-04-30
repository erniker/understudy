---
name: restore
description: "Caveman: restore a Markdown file from its .original.md backup (byte-identical) and remove the backup."
__caveman: true
---

<!-- caveman:command — managed by modules/caveman/bin/install-commands -->

Restore the file the user provides to the byte-identical content of its
`.original.md` backup, then remove the backup.

Steps:

1. Ask the user for the target path if they did not provide one.
2. Verify both the target file and `<target>.original.md` exist.
3. Run `modules/caveman/bin/understudy-compress --restore <path>` from
   the project root (fall back to `scripts/understudy-compress --restore`
   for legacy layouts).
4. Confirm the file is back to the pre-compression content and that the
   backup file has been removed.
5. Do **not** stage or commit. The user reviews the diff first.

If no backup exists, stop and tell the user: there is nothing to restore
because the file was never compressed (or the backup has already been
consumed by a previous `--restore`).
