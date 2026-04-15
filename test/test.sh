#!/usr/bin/env bash
set -o pipefail;
set -o errexit;
set -o errtrace;
set -o nounset;
set -o noclobber;

[[ $(head -1 README.md) == "# restickler" ]] || { echo "Run tests from the project root" && exit 1; }
test_root="$PWD/test"
test_source="$test_root/source"
test_env_file="$test_root/config/restickler/env"
export XDG_CONFIG_HOME="$test_root/config"
export XDG_STATE_HOME="$test_root/state"
export TMPDIR="$test_root/tmp"
export RESTIC_CACHE_DIR="$TMPDIR/restic-cache"
mkdir -p "$TMPDIR" "$RESTIC_CACHE_DIR"

function usage {
  cat <<EOF
Usage: $0 [smoke-test|install-config|full|help]

  smoke-test            Run a smoke test (run '--help' and test exit code)
  install-config        Install the config into the ./test/ dir
  dry-run               Run a simple back/restore as a dry run
  simple                Run a backup/restore with basic options
  full                  Run a backup/restore/forget with all options enabled
  restic-find [PATH]    Run 'restic find' on PATH (default: the test log)
  help                  Show this help
EOF
  exit 0
}

cmd=${1:-help}

function prepare_test_env {
  mkdir -p "$(dirname "$test_env_file")" "$XDG_STATE_HOME/restickler" "$test_source"
  mkdir -p "$XDG_CONFIG_HOME/restickler/exclude"
  [[ -f "$test_env_file" ]] || { echo "Missing test env: run './test/test.sh install-config' first" && exit 1; }
  printf 'restickler test fixture\n' >| "$test_source/example.txt"
  [[ -f "$XDG_CONFIG_HOME/restickler/exclude/default.txt" ]] || printf '# Test exclude rules\n' >| "$XDG_CONFIG_HOME/restickler/exclude/default.txt"
}

case $cmd in
  smoke-test) if "$PWD/bin/restickler" --help &>/dev/null; then echo "Smoke test passed" && exit 0; else echo "Smoke test failed" && exit 1; fi ;;
  install-config) "$PWD/bin/restickler" --install-config ;;
  dry-run) prepare_test_env; "$PWD/bin/restickler" -t backup,restore -nvABHI -b 0 --allow-auto-unlock "$test_source" ;;
  simple) prepare_test_env; "$PWD/bin/restickler" -t backup,restore -vABHI -b 0 --allow-auto-unlock "$test_source" ;;
  full) prepare_test_env; "$PWD/bin/restickler" -vvvABHI -b 0 -f 0 -p 0 -c 0 -d 99% -u 99% -t backup,restore,forget --allow-auto-unlock "$test_source" ;;
  restic-find)
    prepare_test_env
    # shellcheck source=/dev/null
    . "$test_env_file"
    restic find "${2:-$test_source/example.txt}"
    deactivate_restic_env
    ;;
  help) usage ;;
  *) { echo "Unknown command: $cmd" && exit 1; } ;;
esac

echo "The restickler test log might have more details: \"$PWD/test/state/restickler/log\""
