#!/usr/bin/env bats
# Tests for detect_existing_project in wizard.sh
# Covers: stack detection (Node, React, Vue, Angular, .NET, Python, Terraform, Docker),
#         monorepo labeling, Understudy re-deploy detection, empty directory.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
}

teardown() { teardown_tmp; }

# ── Helper: run detection on a given directory ────────────────────────────────
run_detect() {
  detect_existing_project "$1"
}

# ── Empty directory ───────────────────────────────────────────────────────────

@test "empty directory yields no stack and mode=directory" {
  mkdir -p "$TEST_TMP/empty"
  run_detect "$TEST_TMP/empty"
  [ "$EXISTING_MODE" = "directory" ]
  [ -z "$DETECTED_STACK" ]
}

# ── Node.js ───────────────────────────────────────────────────────────────────

@test "detects plain Node.js project" {
  mkdir -p "$TEST_TMP/node/api"
  echo '{"name":"api","dependencies":{"express":"^4"}}' > "$TEST_TMP/node/api/package.json"
  run_detect "$TEST_TMP/node"
  [[ "$DETECTED_STACK" == *"Node.js"* ]]
}

@test "detects React project" {
  mkdir -p "$TEST_TMP/react/web"
  echo '{"name":"web","dependencies":{"react":"^18"}}' > "$TEST_TMP/react/web/package.json"
  run_detect "$TEST_TMP/react"
  [[ "$DETECTED_STACK" == *"React"* ]]
}

@test "detects Vue project" {
  mkdir -p "$TEST_TMP/vue/app"
  echo '{"name":"app","dependencies":{"vue":"^3"}}' > "$TEST_TMP/vue/app/package.json"
  run_detect "$TEST_TMP/vue"
  [[ "$DETECTED_STACK" == *"Vue"* ]]
}

@test "detects Angular project" {
  mkdir -p "$TEST_TMP/ng/app"
  echo '{"name":"app","dependencies":{"@angular/core":"^17"}}' > "$TEST_TMP/ng/app/package.json"
  run_detect "$TEST_TMP/ng"
  [[ "$DETECTED_STACK" == *"Angular"* ]]
}

@test "detects Next.js as React" {
  mkdir -p "$TEST_TMP/next/app"
  echo '{"name":"app","dependencies":{"next":"^14","react":"^18"}}' > "$TEST_TMP/next/app/package.json"
  run_detect "$TEST_TMP/next"
  [[ "$DETECTED_STACK" == *"React"* ]]
}

# ── .NET ──────────────────────────────────────────────────────────────────────

@test "detects single .NET project" {
  mkdir -p "$TEST_TMP/dotnet/src/Api"
  touch "$TEST_TMP/dotnet/src/Api/MyApi.csproj"
  run_detect "$TEST_TMP/dotnet"
  [[ "$DETECTED_STACK" == *".NET"* ]]
}

@test "counts multiple .NET projects" {
  mkdir -p "$TEST_TMP/dotnet/Api" "$TEST_TMP/dotnet/Worker"
  touch "$TEST_TMP/dotnet/Api/Api.csproj"
  touch "$TEST_TMP/dotnet/Worker/Worker.csproj"
  run_detect "$TEST_TMP/dotnet"
  [[ "$DETECTED_STACK" == *".NET(2)"* ]]
}

# ── Python ────────────────────────────────────────────────────────────────────

@test "detects Python via requirements.txt" {
  mkdir -p "$TEST_TMP/py/service"
  touch "$TEST_TMP/py/service/requirements.txt"
  run_detect "$TEST_TMP/py"
  [[ "$DETECTED_STACK" == *"Python"* ]]
}

@test "detects Python via pyproject.toml" {
  mkdir -p "$TEST_TMP/py/service"
  touch "$TEST_TMP/py/service/pyproject.toml"
  run_detect "$TEST_TMP/py"
  [[ "$DETECTED_STACK" == *"Python"* ]]
}

# ── Terraform ─────────────────────────────────────────────────────────────────

@test "detects Terraform" {
  mkdir -p "$TEST_TMP/tf/infra"
  touch "$TEST_TMP/tf/infra/main.tf"
  run_detect "$TEST_TMP/tf"
  [[ "$DETECTED_STACK" == *"Terraform"* ]]
}

# ── Docker ────────────────────────────────────────────────────────────────────

@test "detects Docker Compose at root" {
  mkdir -p "$TEST_TMP/docker"
  touch "$TEST_TMP/docker/docker-compose.yml"
  run_detect "$TEST_TMP/docker"
  [[ "$DETECTED_STACK" == *"Docker"* ]]
}

@test "detects multiple Dockerfiles" {
  mkdir -p "$TEST_TMP/docker/svc1" "$TEST_TMP/docker/svc2"
  touch "$TEST_TMP/docker/svc1/Dockerfile"
  touch "$TEST_TMP/docker/svc2/Dockerfile"
  run_detect "$TEST_TMP/docker"
  [[ "$DETECTED_STACK" == *"Docker"* ]]
}

# ── Shell scripting ──────────────────────────────────────────────────────────

@test "detects shell scripting projects" {
  mkdir -p "$TEST_TMP/shell/scripts"
  touch "$TEST_TMP/shell/scripts/deploy.sh"
  run_detect "$TEST_TMP/shell"
  [[ "$DETECTED_STACK" == *"Shell"* ]]
}

# ── Monorepo ──────────────────────────────────────────────────────────────────

@test "labels as Monorepo when 3+ independent projects found" {
  # .NET + React + Python = 3 independent projects
  mkdir -p "$TEST_TMP/mono/api" "$TEST_TMP/mono/web" "$TEST_TMP/mono/ml"
  touch "$TEST_TMP/mono/api/Api.csproj"
  echo '{"name":"web","dependencies":{"react":"^18"}}' > "$TEST_TMP/mono/web/package.json"
  touch "$TEST_TMP/mono/ml/requirements.txt"
  run_detect "$TEST_TMP/mono"
  [[ "$DETECTED_STACK" == "Monorepo:"* ]]
}

# ── Understudy already deployed ───────────────────────────────────────────────

@test "detects existing Understudy via Copilot files" {
  mkdir -p "$TEST_TMP/us/.github/instructions"
  touch "$TEST_TMP/us/AGENTS.md"
  run_detect "$TEST_TMP/us"
  [ "$EXISTING_MODE" = "understudy" ]
}

@test "detects existing Understudy via Claude Code files" {
  mkdir -p "$TEST_TMP/us/.claude/agents"
  touch "$TEST_TMP/us/CLAUDE.md"
  run_detect "$TEST_TMP/us"
  [ "$EXISTING_MODE" = "understudy" ]
}

@test "detects existing Understudy via Cursor files" {
  mkdir -p "$TEST_TMP/us/.cursor/agents" "$TEST_TMP/us/.cursor/rules"
  touch "$TEST_TMP/us/.cursor/rules/understudy-global.mdc"
  run_detect "$TEST_TMP/us"
  [ "$EXISTING_MODE" = "understudy" ]
}

# ── DETECTED_COMPONENTS ───────────────────────────────────────────────────────

@test "DETECTED_COMPONENTS is populated for React project" {
  mkdir -p "$TEST_TMP/react/web"
  echo '{"name":"web","dependencies":{"react":"^18"}}' > "$TEST_TMP/react/web/package.json"
  run_detect "$TEST_TMP/react"
  [ "${#DETECTED_COMPONENTS[@]}" -gt 0 ]
}
