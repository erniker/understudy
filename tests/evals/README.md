# Caveman evals harness

A small, opt-in harness to defend the savings claim of [caveman mode](../../docs/11-caveman-mode.md)
with reproducible numbers. Two halves:

1. **Dogfood** — runs `scripts/understudy-compress` against every Markdown file
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
./tests/evals/run.sh
```

That orchestrator runs `dogfood.py` and `three_arms.py` and rewrites the
relevant blocks of `RESULTS.md`.

You can also run either half on its own:

```bash
python3 tests/evals/dogfood.py             # default: templates/docs
python3 tests/evals/dogfood.py --targets docs/ templates/  # any tree
python3 tests/evals/three_arms.py
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
`scripts/understudy-compress` for the actual compression so the harness
exercises the **shipped** binary, not a parallel implementation. Re-run
`./tests/evals/run.sh` whenever the role, the compress rules, or the
template fixtures change.
