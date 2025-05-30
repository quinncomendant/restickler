# restickler

A wrapper for [restic](https://restic.net/) that supervises back up, forget, prune, check, and restore test. Designed for macOS, but works on Linux too.

Restickler is stable as of v1.2.0. It runs impeccably on my macOS dev machine and Linux servers, but since your environment might be different, please use at your own risk. If you notice a glitch, please create an [issue](https://github.com/quinncomendant/restickler/issues).

## Features

- Run back up, test restore, and maintenance tasks on a minimal interval schedule. Specify tasks with `-t` (default: `backup,restore,forget,prune,check`). E.g., to schedule back up every 3 hours, and prune every 3 days, use: `-t backup,prune -b 3 -p 72`.
- Skip if there has been no user activity since last back up (`-A`), if on battery power (`-B`), if tethered to an iOS hotspot (`-H`), or if internet is unreliable (`-I`) (macOS only).
- Limit upload and download speed as a percentage of available bandwidth, e.g., `-u 50% -d 50%`.
- Test restoring a unique “canary” file after every back up. This verifies that back up and restore are working.
- Receive notifications of errors and back up delays via [Healthchecks.io](https://healthchecks.io/) (optional).

## Install

1. Install prerequisites: [restic](https://restic.readthedocs.io/en/latest/020_installation.html) and [jq](https://stedolan.github.io/jq/download/). Use [Homebrew](https://brew.sh/) to install on macOS: `brew install restic jq`
2. Install the `restickler` script in `~/bin/` (or wherever you run scripts from):

    ```bash
    mkdir -p ~/bin
    curl -L -o ~/bin/restickler https://raw.githubusercontent.com/quinncomendant/restickler/master/bin/restickler
    chmod 755 ~/bin/restickler
    ```

    (Be sure to add `~/bin` in your shell’s $PATH.)
3. Install example config files:

    ```bash
    restickler --install-config
    ```

    (Files will be added to `~/.config/`, or $XDG_CONFIG_HOME if defined.)

## Set up

1. [Prepare your back up repository](https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html) (GCP’s [Coldline Storage](https://cloud.google.com/storage/docs/storage-classes#coldline) is an easy option)
2. Configure credentials and repository in `~/.config/restickler/env`
3. Configure [exclude paths](https://restic.readthedocs.io/en/latest/040_backup.html#excluding-files) in `~/.config/restickler/exclude/default.txt`
4. Initialize the backup destination: `source ~/.config/restickler/env && restic init`
5. Test your configuration with a dry-run: `restickler -vn $HOME`
6. Back up your home directory: `restickler -v $HOME`
7. Automatically back up hourly by adding this to `crontab -e` (all features enabled for macOS):

    ```cron
    PATH=/Users/YOUR_USERNAME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
    * * * * * restickler -vvABHI -d 75\% -u 75\% -b 1 $HOME >/dev/null
    ```

(For restic to have permission to access your files on macOS you may need to give `cron` [Full Disk Access](https://send.strangecode.com/f/screen-shot-2022-04-10-at-13-25-23.png) in *System Preferences → Security & Privacy → Privacy → Full Disk Access → (click `+` and select `/usr/sbin/cron`)*)

## Update

Get the latest version of `restickler` and `restic` by running their self-update commands:

- `restickler --self-update`
- `restic self-update` or if installed via Homebrew: `"$(readlink -f "$(which restic)")" self-update`

## Usage

Run `restickler -h` to print this usage message:

```
USAGE

    restickler [OPTIONS] SOURCE [SOURCE…]

Back up SOURCE and run maintenance tasks on the configured restic repository.

OPTIONS

    -A                  Abort if there has been no user activity since last back up.
    -B                  Abort if on battery power.
    -b HOURS            Min interval between back up operations (currently every 0 hours).
    -C FILE             Path to environment config file (default: ~/.config/restickler/env).
    -c HOURS            Min interval between check operations (currently every 720 hours).
    -d MBPS|%           Limit download speed in Mb/s or as a percentage of available bandwidth.
    -e FILE             File containing back up exclusion rules, used as --exclude-file=FILE.
    -f HOURS            Min interval between forget operations (currently every 168 hours).
    -H                  Abort if connected to an iOS hotspot.
    -h, --help          Display this help message.
    -I                  Abort if internet is unreliable.
    --allow-auto-unlock Automatically unlock stale repository locks (older than 24h, same host+user, restic not running).
    --install-config    Install example config files (will not overwrite existing files):
                          ~/.config/restickler/env
                          ~/.config/restickler/exclude/default.txt
    -n                  Dry run: print the expected outcome to the screen; don’t actually do anything.
    -p HOURS            Min interval between prune operations (currently every 240 hours).
    -q                  Do not output comprehensive progress report.
    --self-update       Download the replace restickler with the latest release from GitHub.
    -t TASK,TASK,…     A list of tasks to complete on SOURCE (default: backup,restore,forget,prune,check)
    -u MBPS|%           Limit upload speed in Mb/s or as a percentage of available bandwidth.
    -v                  Display verbose output (-vv to list uploaded files; -vvv to show debugging output).
    -V, --version       Print version information.

Restickler, by default, runs these commands in sequence to maintain the full lifecycle of a healthy repository:

    1. `restic backup` (every 0 hours or as specified by -b)
    2. `restic restore` (restore test file from SOURCE/.restickler-canary/UTC_DATE_TIME)
    3. `restic forget` (every 168 hours or as specified by -f)
    4. `restic prune` (every 240 hours or as specified by -p)
    5. `restic check` (every 720 hours or as specified by -c)

Use `-t` to limit which tasks are run, e.g., `-t backup,restore,forget` to run only the first three tasks.

GETTING STARTED

    1. Install example config files: `restickler --install-config`
    2. Configure environment in `~/.config/restickler/env` (see ENVIRONMENT VARIABLES below)
    3. Configure excluded paths in `~/.config/restickler/exclude/default.txt`
    4. Initialize the repo: `source ~/.config/restickler/env && restic init`
    5. Do back up with `restickler $HOME`

For detailed set-up instructions, see https://github.com/quinncomendant/restickler#set-up

ENVIRONMENT VARIABLES

The following environment variables can be defined in `~/.config/restickler/env`, which is
automatically sourced by restickler if it exists. Use `-C FILE` to specify a custom env file.

    RESTIC_REPOSITORY               The restic repository to back up to and maintain.
    RESTIC_PASSWORD_COMMAND         The shell command that outputs the repository password.
                                    (Or use RESTIC_PASSWORD, but this is less secure.)
    GOOGLE_APPLICATION_CREDENTIALS  Path to the GCP Service Account credentials file.
    GOOGLE_PROJECT_ID               GCP project ID.
    HEALTHCHECKS_URL                Healthchecks.io URL to ping on success or failure (optional).

The GOOGLE_* variables can be replaced with variables used by your preferred cloud provider;
see https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html

LOGS

Activity is logged to `~/.local/state/restickler/log`. Use `-vv` to record new and modified files.

EXAMPLES

Back up the entire home directory, except files matched by `~/.config/restickler/exclude/default.txt`:

    restickler $HOME

Back up all Apple Photo libraries, doing back up only, with a custom exclude file:

    restickler -t backup -e ~/.config/restickler/exclude/photoslibrary.txt $HOME/Pictures/*.photoslibrary

Force back up, forget, prune, and check to run by setting intervals to 0 (removing
the `~/.local/state/restickler/last-*-time*` files would also reset the interval timer):

    restickler -b 0 -f 0 -p 0 -c 0 $HOME

A sane configuration for crontab on macOS: double verbosity to log files as they upload,
skip back up when idle, on battery, using hotspot, or unreliable internet, with upload
and download limited to 75% of available bandwidth (cron needs % to be escaped). Although
it runs every 5 minutes, back up will happen at most only once per hour:

    */5 * * * * restickler -vvABHI -d 75\% -u 75\% -b 1 $HOME >/dev/null
```

## Troubleshooting

If restickler stops backing up, check the `~/.local/state/restickler/log` file. Usually, a repository has a stale lock caused by an interrupted back up, with this appearing in the log:

```
Skipping backup because repository is locked
```

Fix this by running `source ~/.config/restickler/env && restic unlock` after confirming no restic processes are running.

## To do

- The retention policy applied with `restic forget` is currently hard coded; it should be configurable via --keep-hourly, --keep-daily, etc.
- Improve configuration of logging level. Currently using -v[-v[-v]] to include more in logs, but would be nice to have a dedicated --log-level option.
- Set I/O and CPU priority (`taskpolicy -c utility` to use only efficiency cores, `taskpolicy -b throttle` to limit I/O).
- Choose a default tag to use with `--keep-tag` for persistent snapshots.
- Improve stale locks detection. Currently, handling stale locks requires manual intervention.

## License

MIT License; see LICENSE for details.

## Disclaimer

This software is provided by the copyright holders and contributors “as is” without support and without warranty as to its quality, merchantability, or fitness for a particular purpose.

## Support

Contact me on [Mastodon](https://mastodon.social/@com) or create a [GitHub issue](https://github.com/quinncomendant/restickler/issues).

Do you find this free software useful? [Say thanks with a coffee!](https://ko-fi.com/strangecode)
