---
name: restore
description: "Caveman: restore a Markdown file from its .original.md backup (byte-identical) and remove the backup."
__caveman: true
---

<!-- caveman:command — managed by modules/caveman/bin/install-commands -->

Restore the file at `$ARGUMENTS` to the byte-identical content of its
`.original.md` backup, then remove the backup.

Steps:

1. Verify both `$ARGUMENTS` and `<$ARGUMENTS>.original.md` exist.
2. Run `modules/caveman/bin/understudy-compress --restore "$ARGUMENTS"`
   (fall back to `scripts/understudy-compress --restore` for legacy
   layouts).
3. Confirm the file is back to the pre-compression content and that the
   backup file has been removed.
4. Do **not** stage or commit. The user reviews the diff first.

If no backup exists, stop and tell the user: there is nothing to restore
because the file was never compressed (or the backup has already been
consumed by a previous `--restore`).
