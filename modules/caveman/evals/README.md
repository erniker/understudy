# Caveman evals harness

A small, opt-in harness to defend the savings claim of [caveman mode](../../docs/11-caveman-mode.md)
with reproducible numbers. Two halves:

1. **Dogfood** — runs `modules/caveman/bin/understudy-compress` against every Markdown file
   under `templates/docs/` and reports per-file token reduction.
2. **Three-arm context measurement** — builds three input bundles for the same
   simulated task and counts tokens:
   - **A. no-caveman** — baseline context only.
   - **B. role** — context + caveman role prepended.
   - **C. role + compress** — context compressed + caveman role compressed +
     prepended.

Both halves write into [`RESULTS.md`](RESULTS.md) between named markers, so
you can re-run them and diff the change.

## Run

```bash
./modules/caveman/evals/run.sh
```

That orchestrator runs `dogfood.py` and `three_arms.py` and rewrites the
relevant blocks of `RESULTS.md`.

You can also run either half on its own:

```bash
python3 modules/caveman/evals/dogfood.py             # default: templates/docs
python3 modules/caveman/evals/dogfood.py --targets docs/ templates/  # any tree
python3 modules/caveman/evals/three_arms.py
```

## Token measurement

The harness uses **tiktoken** with the `cl100k_base` encoding when available
(the same tokeniser used by ChatGPT and Claude's compatibility layer). Without
tiktoken it falls back to whitespace-delimited word count and labels its
output `word-count`. Word count is fine for relative comparisons but should
not be cited as exact API token cost.

To install tiktoken locally:

```bash
python3 -m pip install --user tiktoken
# or, if your distro enforces PEP 668:
pipx install tiktoken
```

The compress script ships its own optional-tiktoken consent flow; the evals
harness does not prompt — it just uses what is on `sys.path`.

## Regenerating `RESULTS.md` with real `cl100k_base` numbers

The committed `RESULTS.md` should declare `Token method: cl100k_base`. There
are two supported ways to regenerate it.

### Route A — CI workflow (canonical)

`.github/workflows/evals.yml` runs the harness on `ubuntu-latest` with
`tiktoken` pre-installed and uploads the regenerated `RESULTS.md` as a
build artifact. The maintainer commits it to the repo when the numbers
change meaningfully.

Triggers:

- **Manual** (`workflow_dispatch`): Actions tab → *Evals (real tiktoken)*
  → *Run workflow*. Optional input pins the Python version (default `3.12`).
- **Weekly** (`schedule`): Mondays 06:00 UTC. Catches `tiktoken` wheel
  regressions early.

The job is **non-blocking** and **not a required PR check** — the harness
is opt-in by design. The lightweight word-count smoke that runs on PRs
touching the compressor lives in `evals-smoke.yml`.

### Route B — Local personal machine

Pick whichever Python toolchain matches your environment. Each recipe ends
with `./modules/caveman/evals/run.sh` and produces a `RESULTS.md` labelled
`Token method: cl100k_base`. Commit it from the repo root.

#### `uv` (recommended; installs its own Python 3.12)

```bash
uv venv --python 3.12 .venv-evals
# Bash / zsh:
source .venv-evals/bin/activate
# Windows PowerShell:
# .venv-evals\Scripts\Activate.ps1
uv pip install tiktoken
./modules/caveman/evals/run.sh
```

#### Stock `python3.12` + `pip`

```bash
python3.12 -m venv .venv-evals
# Bash / zsh:
source .venv-evals/bin/activate
# Windows PowerShell:
# .venv-evals\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install tiktoken
./modules/caveman/evals/run.sh
```

#### `pipx` (system-wide, no venv juggling)

```bash
pipx install tiktoken
./modules/caveman/evals/run.sh
```

> **Corporate proxy?** Most TLS-inspecting proxies (e.g. Zscaler) return
> 403 for `files.pythonhosted.org` and break `pip install tiktoken`. If
> you hit that, fall back to **Route A** — the CI workflow has clean
> network access — and skip the local install.

> **Python 3.14?** As of this writing there is no `tiktoken` wheel for
> CPython 3.14. Pin to 3.12 (or whichever the latest version with a
> published wheel is) for the venv above.

The repo `.gitignore` already covers `.venv*`, so the harness venv will
not be committed by accident.

## Methodology notes

### What this harness measures

- **Input tokens** delivered to a hypothetical model: the role file, the
  bundle (template AGENTS.md, spec.md, decisions.md), and the user task.
- The same arithmetic that determines context-window usage and per-call
  input-token billing.

### What this harness does NOT measure

- **Output tokens**. The caveman role's primary win is on the output side
  ("makes agents speak shorter"), and there is no honest way to measure that
  without sending all three arms to a real model and comparing replies. If
  your team wires this harness into your agent runner, the natural extension
  is a fourth column with "model output tokens" recorded for each arm.
- **Quality**. Token reduction is meaningless if the model produces worse
  answers. Caveman mode trades brevity for terseness, not for correctness;
  hold the bar with whatever quality eval you already use (judge models,
  human spot-checks, regression tests).

### Why arm B is **larger** than A

Adding the role prepends ~500–700 tokens of instructions. That is the
*investment*; the return is on the output side (brief replies). Arm C
amortises some of that investment by compressing the bundle, but if the
bundle is already terse (lots of tables and bullets, like the Understudy
templates) compression cannot recover the full cost of the role on input.
When the bundle is prose-heavy the picture inverts and C drops below A.
The RESULTS.md in this directory shows real numbers from the shipped
template fixtures — your project's bundle will differ.

### Reproducibility

Both Python scripts are stdlib-only by default; both shell out to
`modules/caveman/bin/understudy-compress` for the actual compression so the harness
exercises the **shipped** binary, not a parallel implementation. Re-run
`./modules/caveman/evals/run.sh` whenever the role, the compress rules, or the
template fixtures change.
