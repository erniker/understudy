#!/usr/bin/env bats
# Tests for templates/.claude/hooks/guardrails-check.sh
# Covers: each destructive pattern is blocked (exit 2),
#         secret-file patterns warn but allow (exit 0),
#         safe commands are allowed (exit 0).

HOOK="${BATS_TEST_DIRNAME}/../../templates/.claude/hooks/guardrails-check.sh"

# ── Destructive patterns — must be blocked (exit 2) ──────────────────────────

@test "blocks: rm -rf" {
  run bash "$HOOK" "rm -rf /tmp/mydir"
  [ "$status" -eq 2 ]
}

@test "blocks: rm -r /" {
  run bash "$HOOK" "rm -r /var/data"
  [ "$status" -eq 2 ]
}

@test "blocks: terraform destroy" {
  run bash "$HOOK" "terraform destroy -auto-approve"
  [ "$status" -eq 2 ]
}

@test "blocks: kubectl delete" {
  run bash "$HOOK" "kubectl delete deployment my-app"
  [ "$status" -eq 2 ]
}

@test "blocks: docker system prune" {
  run bash "$HOOK" "docker system prune -af"
  [ "$status" -eq 2 ]
}

@test "blocks: DROP TABLE" {
  run bash "$HOOK" "DROP TABLE users;"
  [ "$status" -eq 2 ]
}

@test "blocks: DROP DATABASE" {
  run bash "$HOOK" "DROP DATABASE production;"
  [ "$status" -eq 2 ]
}

@test "blocks: TRUNCATE TABLE" {
  run bash "$HOOK" "TRUNCATE TABLE orders;"
  [ "$status" -eq 2 ]
}

@test "blocks: DELETE FROM" {
  run bash "$HOOK" "DELETE FROM customers WHERE id > 0;"
  [ "$status" -eq 2 ]
}

@test "blocks: git push --force" {
  run bash "$HOOK" "git push --force origin main"
  [ "$status" -eq 2 ]
}

@test "blocks: git push -f" {
  run bash "$HOOK" "git push -f origin main"
  [ "$status" -eq 2 ]
}

@test "blocks: git rebase" {
  run bash "$HOOK" "git rebase main"
  [ "$status" -eq 2 ]
}

@test "blocks: force-push" {
  run bash "$HOOK" "force-push to remote"
  [ "$status" -eq 2 ]
}

@test "blocks: rmdir" {
  run bash "$HOOK" "rmdir /tmp/emptydir"
  [ "$status" -eq 2 ]
}

@test "blocked output contains GUARDRAIL message" {
  run bash "$HOOK" "rm -rf /tmp/test"
  [[ "$output" == *"GUARDRAIL"* ]]
}

@test "blocked output names the detected pattern" {
  run bash "$HOOK" "terraform destroy"
  [[ "$output" == *"terraform destroy"* ]]
}

# ── Case insensitivity ────────────────────────────────────────────────────────

@test "blocks uppercase DROP TABLE" {
  run bash "$HOOK" "DROP TABLE users;"
  [ "$status" -eq 2 ]
}

@test "blocks lowercase drop table" {
  run bash "$HOOK" "drop table users;"
  [ "$status" -eq 2 ]
}

@test "blocks mixed case Terraform Destroy" {
  run bash "$HOOK" "Terraform Destroy"
  [ "$status" -eq 2 ]
}

# ── Secret-file patterns — warn but allow (exit 0) ───────────────────────────

@test "allows (with warning): .env file access" {
  run bash "$HOOK" "cat .env"
  [ "$status" -eq 0 ]
}

@test "allows (with warning): .key file access" {
  run bash "$HOOK" "cat server.key"
  [ "$status" -eq 0 ]
}

@test "allows (with warning): .pem file access" {
  run bash "$HOOK" "openssl x509 -in cert.pem"
  [ "$status" -eq 0 ]
}

@test "allows (with warning): secrets/ directory access" {
  run bash "$HOOK" "ls secrets/"
  [ "$status" -eq 0 ]
}

@test "allows (with warning): credentials reference" {
  run bash "$HOOK" "cat credentials.json"
  [ "$status" -eq 0 ]
}

# ── Safe commands — must be allowed (exit 0) ──────────────────────────────────

@test "allows: git status" {
  run bash "$HOOK" "git status"
  [ "$status" -eq 0 ]
}

@test "allows: git add" {
  run bash "$HOOK" "git add src/main.ts"
  [ "$status" -eq 0 ]
}

@test "allows: git commit" {
  run bash "$HOOK" "git commit -m 'feat: add feature'"
  [ "$status" -eq 0 ]
}

@test "allows: git push (normal, no force)" {
  run bash "$HOOK" "git push origin feature/my-branch"
  [ "$status" -eq 0 ]
}

@test "allows: npm install" {
  run bash "$HOOK" "npm install"
  [ "$status" -eq 0 ]
}

@test "allows: npm test" {
  run bash "$HOOK" "npm test"
  [ "$status" -eq 0 ]
}

@test "allows: terraform plan" {
  run bash "$HOOK" "terraform plan"
  [ "$status" -eq 0 ]
}

@test "allows: terraform apply" {
  run bash "$HOOK" "terraform apply"
  [ "$status" -eq 0 ]
}

@test "allows: kubectl get pods" {
  run bash "$HOOK" "kubectl get pods"
  [ "$status" -eq 0 ]
}

@test "allows: docker build" {
  run bash "$HOOK" "docker build -t myapp ."
  [ "$status" -eq 0 ]
}

@test "allows: ls -la" {
  run bash "$HOOK" "ls -la"
  [ "$status" -eq 0 ]
}

@test "allows: empty input" {
  run bash "$HOOK" ""
  [ "$status" -eq 0 ]
}

@test "allows: SELECT query" {
  run bash "$HOOK" "SELECT * FROM users;"
  [ "$status" -eq 0 ]
}
