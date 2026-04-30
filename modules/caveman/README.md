# Caveman module

Opt-in, self-contained module that adds **token-efficient communication** to
an Understudy deployment. Inspired by
[JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) (MIT).

## What it ships

| Asset | Purpose |
| --- | --- |
| [`role.instructions.md`](role.instructions.md) | The `caveman` role — terse, token-efficient prose style. |
| [`bin/understudy-compress`](bin/understudy-compress) | Python 3.8+ compressor that rewrites Markdown in place, preserving code/paths/URLs and creating a `.original.md` backup. |
| [`bin/requirements.txt`](bin/requirements.txt) | Optional `tiktoken` for accurate `cl100k_base` token measurements. |
| [`evals/`](evals/) | Token-reduction evaluation harness (`run.sh` regenerates `RESULTS.md`). |
| [`tests/`](tests/) | Bats coverage for the role, the compressor and the wizard's `--caveman` flag. |

The user-facing chapter for caveman lives in
[`docs/11-caveman-mode.md`](../../docs/11-caveman-mode.md) (kept at its
historical path so existing external links keep working).

## How to enable it

```bash
./wizard.sh --caveman          # add the caveman role at deploy time
./wizard.sh --add-member caveman   # add it to an existing deployment
```

The flag is discovered automatically from this directory's `module.yaml`;
you do not need to edit `wizard.sh` to register a new module.

## How to remove the module entirely

This is the whole point of the `modules/<name>/` layout: removing the
feature is one operation.

```bash
rm -rf modules/caveman
```

Then update:

- `docs/11-caveman-mode.md` (delete or mark as removed)
- `README.md` and `CHANGELOG.md` (note the removal)

That's it. There are no orphan references inside `wizard.sh`,
`install.sh` or the test suite — every caveman asset lives under this
directory.

## Adding a new module

Copy the structure of `modules/caveman/` to `modules/<your-module>/` and
fill in `module.yaml`. The wizard picks it up on the next run.
