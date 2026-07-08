#!/usr/bin/env bash
# mock-adapter.sh — reference LAB ADAPTER implementation (spectrocloud-poc-docs).
#
# Implements the adapter contract with no infrastructure at all: every host role
# "runs" locally. Used by the skill's self-tests and useful as a template when
# writing a real adapter (see references/testing.md for the contract).
#
# Contract:
#   mock-adapter.sh setup [--suite FILE]   -> JSON hosts map on stdout
#   mock-adapter.sh env                    -> KEY=VALUE lines on stdout
#   mock-adapter.sh exec <host> <script>   -> run script (locally here), exit code passes through
#   mock-adapter.sh teardown [--suite FILE]-> idempotent cleanup
#
# Environment knobs (all optional, for tests):
#   MOCK_HOSTS      comma-separated role names to report (default: node)
#   MOCK_ENV        extra KEY=VALUE pairs to emit from `env` (comma-separated)
#   MOCK_STATE_DIR  directory where setup/teardown drop marker files
#   MOCK_FAIL_SETUP if set, `setup` exits 1 (failure-path testing)
set -euo pipefail

cmd="${1:-}"
shift || true

state_dir="${MOCK_STATE_DIR:-}"

case "$cmd" in
  setup)
    [ -n "${MOCK_FAIL_SETUP:-}" ] && { echo "mock: setup forced to fail" >&2; exit 1; }
    [ -n "$state_dir" ] && { mkdir -p "$state_dir"; date +%s > "$state_dir/setup.marker"; }
    roles="${MOCK_HOSTS:-node}"
    json='{"adapter": "mock", "hosts": {'
    first=1
    IFS=',' read -ra arr <<< "$roles"
    for role in "${arr[@]}"; do
      [ $first -eq 0 ] && json+=', '
      json+="\"$role\": {\"address\": \"127.0.0.1\", \"user\": \"$(id -un)\"}"
      first=0
    done
    json+='}}'
    echo "$json"
    ;;
  env)
    echo "PALETTE_API_KEY=mock-palette-api-key-000000"
    echo "PROJECT_UID=mockproject0000000000000"
    if [ -n "${MOCK_ENV:-}" ]; then
      IFS=',' read -ra pairs <<< "$MOCK_ENV"
      printf '%s\n' "${pairs[@]}"
    fi
    ;;
  exec)
    host="${1:?exec needs <host>}"
    script="${2:?exec needs <script>}"
    [ -f "$script" ] || { echo "mock: no such script: $script" >&2; exit 1; }
    # All roles execute locally in the mock. A real adapter would ssh/scp here.
    MOCK_EXEC_HOST="$host" bash "$script"
    ;;
  teardown)
    # Idempotent: succeeds whether or not setup ever ran.
    [ -n "$state_dir" ] && { mkdir -p "$state_dir"; date +%s > "$state_dir/teardown.marker"; }
    echo "mock: teardown complete" >&2
    ;;
  *)
    echo "usage: mock-adapter.sh {setup|env|exec <host> <script>|teardown}" >&2
    exit 2
    ;;
esac
