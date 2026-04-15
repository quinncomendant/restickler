#!/usr/bin/env bash
set -o pipefail;
set -o errexit;
set -o errtrace;
set -o nounset;
set -o noclobber;

[[ $(head -1 README.md) == "# restickler" ]] || { echo "Run tests from the project root" && exit 1; }
export XDG_CONFIG_HOME="$PWD/test/config"
export XDG_STATE_HOME="$PWD/test/state"

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
logfile="$PWD/test/state/restickler/log"
case $cmd in
  smoke-test) if "$PWD/bin/restickler" --help &>/dev/null; then echo "Smoke test passed" && exit 0; else echo "Smoke test failed" && exit 1; fi ;;
  install-config) "$PWD/bin/restickler" --install-config ;;
  dry-run) "$PWD/bin/restickler" -t backup,restore -nvABHI -b 0 --allow-auto-unlock "$PWD/test" ;;
  simple) "$PWD/bin/restickler" -t backup,restore -vABHI -b 0 --allow-auto-unlock "$PWD/test" ;;
  full) "$PWD/bin/restickler" -vvvABHI -b 0 -f 0 -p 0 -c 0 -d 99% -u 99% -t backup,restore,forget --allow-auto-unlock "$PWD/test" ;;
  restic-find)
    # shellcheck source=/dev/null
    . "$PWD/test/config/restickler/env"
    restic find "${2:-$logfile}"
    deactivate_restic_env
    ;;
  help) usage ;;
  *) { echo "Unknown command: $cmd" && exit 1; } ;;
esac

echo "The restickler test log might have more details: \"$PWD/test/state/restickler/log\""
