# AGENTS.md — Restickler

## Overview
Single-file Bash CLI (`bin/restickler`, ~955 lines) wrapping [restic](https://restic.net/) for automated backup lifecycle (backup → test-restore → forget → prune → check). Config lives in `config/env` (env vars) and `config/exclude/*.txt` (exclusion rules). No build step; tests live in `test/test.sh`.

## Commands
- **Dry run (simple):** `restickler -nvAHI -b 0 -t backup,restore --allow-auto-unlock $HOME`
- **Dry run (full):** `restickler -nvvvABHI -b 0 -f 0 -p 0 -c 0 -d 99% -u 99% -t backup,restore,forget --allow-auto-unlock $HOME`
- **Run (production):** `restickler -vvAHI -b 1 -t backup,restore --allow-auto-unlock $HOME`

## Tests
- **Lint:** `shellcheck bin/restickler`
- **Test harness usage:** `./test/test.sh help`
- **Run full tests:** `./test/test.sh full`

## Code Style (Bash)
- Strict mode: `set -o pipefail errexit errtrace nounset noclobber`.
- Quote all variable expansions; use `[[ ]]` for tests, `(( ))` for arithmetic.
- Semicolons terminate variable assignments and statements (e.g., `local foo='bar';`).
- Functions use `function _name {` syntax with a leading underscore for internal helpers.
- Logging hierarchy: `_debug` (requires `-vvv`), `_info` (`-v`), `_notice` (always), `_warning` (stderr), `_error` (fatal, sends USR1).
- Errors call `_error` which logs, pings Healthchecks.io, and terminates via `kill -USR1`.
- XDG Base Directory spec for config (`$XDG_CONFIG_HOME/restickler/`) and state (`$XDG_STATE_HOME/restickler/`).
- Dependencies: `restic curl jq bc tr awk sed readlink`.
