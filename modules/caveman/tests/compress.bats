#!/usr/bin/env bats
# Tests for modules/caveman/bin/understudy-compress (Python implementation).

load '../../../tests/lib/helpers'

# Resolve a Python interpreter once per suite. CI installs python3 explicitly.
if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  PY=""
fi

COMPRESS_BIN="${BATS_TEST_DIRNAME}/../bin/understudy-compress"
PROSE_FIXTURE="${BATS_TEST_DIRNAME}/../../../tests/fixtures/compress/prose.md"

# Wrapper that always invokes the script via the resolved interpreter.
SCRIPT() {
  if [ -z "$PY" ]; then
    skip "no python interpreter available"
  fi
  "$PY" "$COMPRESS_BIN" --no-install "$@"
}

setup() {
  setup_tmp
  cp "$PROSE_FIXTURE" "$TEST_TMP/prose.md"
}

teardown() {
  teardown_tmp
}

@test "compress: script is executable and shows help" {
  run SCRIPT --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"understudy-compress"* ]]
  [[ "$output" == *"--restore"* ]]
}

@test "compress: refuses to operate on file outside CWD" {
  outside="$(mktemp)"
  echo "x" > "$outside"
  cd "$TEST_TMP"
  run SCRIPT "$outside"
  rm -f "$outside"
  [ "$status" -ne 0 ]
  [[ "$output" == *"outside"* ]]
}

@test "compress: refuses .env-style filenames" {
  cd "$TEST_TMP"
  echo "x" > ".env.md"
  run SCRIPT .env.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"sensitive path"* ]]
}

@test "compress: refuses files with sensitive names (secret, credential)" {
  cd "$TEST_TMP"
  echo "x" > "my-secret-doc.md"
  run SCRIPT my-secret-doc.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"sensitive path"* ]]
}

@test "compress: refuses content with AWS access key" {
  cd "$TEST_TMP"
  printf '# doc\nAKIAIOSFODNN7EXAMPLE here\n' > with-aws.md
  run SCRIPT with-aws.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"sensitive"* ]]
}

@test "compress: refuses content with PEM private key" {
  cd "$TEST_TMP"
  printf -- '# doc\n-----BEGIN RSA PRIVATE KEY-----\nABCD\n-----END RSA PRIVATE KEY-----\n' > with-pem.md
  run SCRIPT with-pem.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"sensitive"* ]]
}

@test "compress: refuses symlinks" {
  cd "$TEST_TMP"
  echo "hello" > target.md
  if ! ln -s target.md link.md 2>/dev/null; then
    skip "symlinks not supported on this filesystem"
  fi
  # Verify it really is a symlink before testing (Git Bash on Windows may copy)
  [ -L link.md ] || skip "ln created a copy, not a symlink"
  run SCRIPT link.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"symlink"* ]]
}

@test "compress: backup file is byte-identical to original" {
  cd "$TEST_TMP"
  cp prose.md original.snapshot
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  [ -f prose.original.md ]
  diff -q prose.original.md original.snapshot
}

@test "compress: code blocks are preserved byte-identical" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  grep -q 'echo "the a an please simply"' prose.md
  grep -q '# this fenced block must remain byte-identical' prose.md
}

@test "compress: template tokens like {{PROJECT_NAME}} are preserved" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  grep -q '{{PROJECT_NAME}}' prose.md
  grep -q '{{ROLE_DESCRIPTION}}' prose.md
}

@test "compress: GUARDRAILS markers are preserved" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  grep -q 'GUARDRAILS_START' prose.md
  grep -q 'GUARDRAILS_END' prose.md
}

@test "compress: URLs are preserved intact" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  grep -q 'https://example.com/path/to/page' prose.md
}

@test "compress: paths and versions and dates are preserved" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  grep -q '/etc/passwd' prose.md
  grep -q 'v1.2.3' prose.md
  grep -q '2026-04-29' prose.md
}

@test "compress: no sentinel tokens leak into output" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  ! grep -q '__USP_' prose.md
}

@test "compress: prose fixture shrinks at least 15% in word count" {
  cd "$TEST_TMP"
  before=$(awk 'BEGIN{n=0}{n+=NF}END{print n}' prose.md)
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  after=$(awk 'BEGIN{n=0}{n+=NF}END{print n}' prose.md)
  # Avoid bash arithmetic on floats: integer-only.
  saved=$(( before - after ))
  threshold=$(( before * 15 / 100 ))
  [ "$saved" -ge "$threshold" ]
}

@test "compress: --dry-run does not modify the file or create a backup" {
  cd "$TEST_TMP"
  cp prose.md snapshot.md
  run SCRIPT --dry-run prose.md
  [ "$status" -eq 0 ]
  diff -q prose.md snapshot.md
  [ ! -f prose.original.md ]
}

@test "compress: --restore returns the file to byte-identical original" {
  cd "$TEST_TMP"
  cp prose.md snapshot.md
  SCRIPT prose.md
  [ -f prose.original.md ]
  run SCRIPT --restore prose.md
  [ "$status" -eq 0 ]
  diff -q prose.md snapshot.md
  [ ! -f prose.original.md ]
}

@test "compress: --restore fails when no backup exists" {
  cd "$TEST_TMP"
  echo "x" > untouched.md
  run SCRIPT --restore untouched.md
  [ "$status" -ne 0 ]
}

@test "compress: removes filler word 'just' on prose lines" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  # The line "Just a final note ..." should no longer start with "Just "
  ! grep -q '^Just a final note' prose.md
}

@test "compress: removes phrase 'It is important to note that'" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  ! grep -qi 'It is important to note that' prose.md
}

@test "compress: replaces 'due to the fact that' with 'because'" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  ! grep -qi 'due to the fact that' prose.md
  grep -qi 'because' prose.md
}

@test "compress: replaces 'in order to' with 'to'" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  ! grep -qi 'in order to' prose.md
}

@test "compress: removes hedging phrases (you should, make sure to)" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  ! grep -qi 'you should always' prose.md
  ! grep -qi 'make sure to' prose.md
  ! grep -qi 'remember to' prose.md
}

@test "compress: removes new filler words (however, furthermore, additionally)" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  ! grep -qi 'furthermore' prose.md
  ! grep -qi 'additionally' prose.md
  ! grep -qi 'essentially' prose.md
  ! grep -qi 'consequently' prose.md
}

@test "compress: replaces 'at this point in time' with 'now'" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  ! grep -qi 'at this point in time' prose.md
}

@test "compress: replaces 'in the event that' with 'if'" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  ! grep -qi 'in the event that' prose.md
}

@test "compress: replaces 'with regard to' with 'about'" {
  cd "$TEST_TMP"
  run SCRIPT prose.md
  [ "$status" -eq 0 ]
  ! grep -qi 'with regard to' prose.md
}

# ── LLM mode tests ──────────────────────────────────────────────────────────

@test "compress: --llm flag is accepted by help" {
  run SCRIPT --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--llm"* ]]
}

@test "compress: --llm falls back to regex when claude CLI is not on PATH" {
  cd "$TEST_TMP"
  # Ensure claude is not available by removing it from PATH but keep python
  PY_DIR="$(dirname "$(command -v "$PY")")"
  export PATH="$PY_DIR:/usr/bin:/bin"
  run SCRIPT --llm prose.md
  [ "$status" -eq 0 ]
  # Should still compress (regex fallback)
  [[ "$output" == *"regex"* ]] || [[ "$output" == *"falling back"* ]] || [[ "$output" == *"Mode: regex"* ]]
}

@test "compress: --llm --dry-run does not modify the file" {
  cd "$TEST_TMP"
  cp prose.md snapshot.md
  run SCRIPT --llm --dry-run prose.md
  [ "$status" -eq 0 ]
  diff -q prose.md snapshot.md
  [ ! -f prose.original.md ]
}

@test "compress: --llm preserves code blocks on regex fallback" {
  cd "$TEST_TMP"
  PY_DIR="$(dirname "$(command -v "$PY")")"
  export PATH="$PY_DIR:/usr/bin:/bin"
  run SCRIPT --llm prose.md
  [ "$status" -eq 0 ]
  grep -q 'echo "the a an please simply"' prose.md
  grep -q '# this fenced block must remain byte-identical' prose.md
}
