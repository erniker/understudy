#!/usr/bin/env bats
# Tests for normalize_path in wizard.sh
# Covers: Windows paths (backslashes, drive letters), Unix paths (Linux/macOS),
#         relative paths, and mixed slash styles — to guarantee the wizard works
#         identically on Windows (Git Bash), Linux and macOS.

load "../lib/helpers"

setup() {
  source_wizard_functions
}

# ── Windows paths (Git Bash on Windows) ──────────────────────────────────────

@test "normalizes Windows path with backslashes (C:\\...)" {
  run normalize_path 'C:\Users\jose\OneDrive\Escritorio\cursor'
  [ "$status" -eq 0 ]
  [ "$output" = "/c/Users/jose/OneDrive/Escritorio/cursor" ]
}

@test "normalizes Windows path with forward slashes (C:/...)" {
  run normalize_path 'C:/Users/jose/projects'
  [ "$output" = "/c/Users/jose/projects" ]
}

@test "normalizes drive letter to lowercase" {
  run normalize_path 'D:\proyectos\mi-app'
  [ "$output" = "/d/proyectos/mi-app" ]
}

@test "normalizes uppercase drive letter" {
  run normalize_path 'Z:\work'
  [ "$output" = "/z/work" ]
}

@test "normalizes mixed slashes in Windows path" {
  run normalize_path 'C:\Users/jose\projects/app'
  [ "$output" = "/c/Users/jose/projects/app" ]
}

@test "normalizes Windows path with trailing backslash" {
  run normalize_path 'C:\Users\jose\'
  [ "$output" = "/c/Users/jose/" ]
}

# ── Unix paths (Linux / macOS) ────────────────────────────────────────────────

@test "leaves absolute Unix path unchanged" {
  run normalize_path '/home/jose/projects'
  [ "$output" = "/home/jose/projects" ]
}

@test "leaves macOS absolute path unchanged" {
  run normalize_path '/Users/jose/projects'
  [ "$output" = "/Users/jose/projects" ]
}

@test "leaves /tmp path unchanged" {
  run normalize_path '/tmp/my-project'
  [ "$output" = "/tmp/my-project" ]
}

# ── Relative paths (any OS) ───────────────────────────────────────────────────

@test "leaves dot (current dir) unchanged" {
  run normalize_path '.'
  [ "$output" = "." ]
}

@test "leaves relative path unchanged" {
  run normalize_path '../projects'
  [ "$output" = "../projects" ]
}

@test "leaves relative path with subdir unchanged" {
  run normalize_path 'projects/my-app'
  [ "$output" = "projects/my-app" ]
}

# ── Already-normalized Git Bash paths ────────────────────────────────────────

@test "leaves Git Bash mount path unchanged (/c/...)" {
  run normalize_path '/c/Users/jose/projects'
  [ "$output" = "/c/Users/jose/projects" ]
}

@test "leaves Git Bash mount path unchanged (/d/...)" {
  run normalize_path '/d/work/project'
  [ "$output" = "/d/work/project" ]
}
