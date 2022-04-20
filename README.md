# restickler

A wrapper for [restic](https://restic.net/) that supervises back up, forget, prune, check, and restore test. Designed for macOS, but works on Linux too.

Restickler is considered “beta quality” software, and is in active development. Use at your own risk.

## Features

- Run back up and maintenance functions (forget, prune, and check) on a minimal interval schedule. E.g., schedule back up to every 3 hours with `-b 3`, and prune every 3 days with `-p 72`.
- Skip if there has been no user activity since last back up (`-A`), if on battery power (`-B`), if tethered to an iOS hotspot (`-H`), or if internet is unreliable (`-I`) (macOS only).
- Limit upload and download speed as a percentage of available bandwidth, e.g., `-u 50% -d 50%` (macOS only).
- Test restoring a unique “canary” file after every back up. This verifies that back up and restore are working.
- Receive notifications of errors and back up delays via [Healthchecks.io](https://healthchecks.io/) (optional).

## Install

1. Install prerequisites: [restic](https://restic.readthedocs.io/en/latest/020_installation.html) and [jq](https://stedolan.github.io/jq/download/). Use [Homebrew](https://brew.sh/) to install on macOS: `brew install restic jq`
2. Install the `restickler` script in `~/bin/`:

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

1. [Prepare your back up repository](https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html) (GCP’s [Coldline Storage](https://cloud.google.com/storage/docs/storage-classes#coldline) is a great choice)
2. Configure credentials and repository in `~/.config/restickler/env`
3. Configure [exclude paths](https://restic.readthedocs.io/en/latest/040_backup.html#excluding-files) in `~/.config/restickler/exclude/default.txt`
4. Initialize the backup destination, e.g., if using GCP Storage: `source ~/.config/restickler/env && restic -r gs:YOUR_BUCKET_NAME:/ init`
5. Test your configuration with a dry-run: `restickler -vn $HOME`
6. Back up your home directory: `restickler -v $HOME`
7. Automatically back up hourly by adding this to `crontab -e`:

    ```cron
    PATH=/Users/YOUR_USERNAME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
    * * * * * restickler -vvABHI -d 75\% -u 75\% -b 1 $HOME >/dev/null
    ```
    
(For restic to have permission to access your files you may need to give `cron` [Full Disk Access](https://send.strangecode.com/f/screen-shot-2022-04-10-at-13-25-23.png) in *System Preferences → Security & Privacy → Privacy → Full Disk Access → (click + and select `/usr/sbin/cron`)*)

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

    -b HOURS          Min interval between back up operations (currently every 0 hours).
    -c HOURS          Min interval between check operations (currently every 168 hours).
    -d MBPS|%         Limit download speed in Mb/s or as a percentage of available bandwidth.
    -e FILE           File containing back up exclusion rules, used as --exclude-file=FILE.
    -f HOURS          Min interval between forget operations (currently every 24 hours).
    -h                Display this help message.
    --install-config  Install example config files (will not overwrite existing files):
                        ~/.config/restickler/env
                        ~/.config/restickler/exclude/default.txt
    -n                Dry run: print the expected outcome to the screen; don’t actually do anything.
    -p HOURS          Min interval between prune operations (currently every 240 hours).
    -q                Do not output comprehensive progress report.
    --self-update     Download the replace restickler with the latest release from GitHub.
    -u MBPS|%         Limit upload speed in Mb/s or as a percentage of available bandwidth.
    -v                Display verbose output (-vv to list uploaded files; -vvv to show debugging output).
    -A                Abort if there has been no user activity since last back up.
    -B                Abort if on battery power.
    -H                Abort if connected to an iOS hotspot.
    -I                Abort if internet is unreliable.
    -V                Print version information.

Restickler runs the following commands to maintain the full lifecycle of a healthy repository:

    1. `restic backup` (every 0 hours or as specified by -b)
    2. `restic restore` (restore test file from SOURCE1/.restickler-canary/UTC_DATE_TIME)
    3. `restic forget` (every 24 hours or as specified by -f)
    4. `restic prune` (every 240 hours or as specified by -p)
    5. `restic check` (every 168 hours or as specified by -c)

GETTING STARTED

    1. Install example config files: `restickler --install-config`
    2. Configure environment in `~/.config/restickler/env` (see ENVIRONMENT VARIABLES below)
    3. Configure excluded paths in `~/.config/restickler/exclude/default.txt`
    4. Initialize the repo: `source ~/.config/restickler/env && restic -r gs:YOUR_BUCKET_NAME:/ init`
    5. Do back up with `restickler $HOME`

For detailed set-up instructions, see https://github.com/quinncomendant/restickler#set-up

ENVIRONMENT VARIABLES

The following environment variables can be defined in `~/.config/restickler/env`, which is
automatically included by restickler if it exists:

    RESTIC_REPOSITORY               The restic repository to back up to and maintain.
    RESTIC_PASSWORD_COMMAND         The shell command that outputs the repository password.
                                    (Or use RESTIC_PASSWORD, but this is less secure.)
    GOOGLE_APPLICATION_CREDENTIALS  Path to the GCP Service Account credentials file.
    GOOGLE_PROJECT_ID               GCP project ID.
    HEALTHCHECKS_URL                Healthchecks.io URL to ping on success or failure (optional).

The GOOGLE_* variables can be replaced by the cloud-provider of your choice;
see https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html

LOGS

Activity is logged to `~/.local/state/restickler/log`. Use `-vv` to record new and modified files.

EXAMPLES

Back up the entire home directory, except files matched by `~/.config/restickler/exclude/default.txt`:

    restickler $HOME

Back up all Apple Photo libraries, with a custom exclude file:

    restickler -e ~/.config/restickler/exclude/photoslibrary.txt $HOME/Pictures/*.photoslibrary

Force back up, forget, prune, and check to run by setting intervals to 0 (removing
the `~/.local/state/restickler/last-*-time*` files would also reset the interval timer):

    restickler -b 0 -f 0 -p 0 -c 0 $HOME

A sane configuration for crontab: double verbosity to log files as they upload,
skip back up when idle, on battery, using hotspot, or unreliable internet, with
upload and download limited to 75% of available bandwidth (cron needs % to be escaped):

    */7 * * * * restickler -vvABHI -d 75\% -u 75\% -b 1 $HOME >/dev/null
```

## To do

- The retention policy applied with `restic forget` is currently hard coded; it should be configurable via --keep-hourly, --keep-daily, etc.
- Improve configuration of logging level. Currently using -v[-v[-v]] to include more in logs, but would be nice to have a dedicated --log-level option.

## License

MIT License; see LICENSE for details.

## Disclaimer

This software is provided by the copyright holders and contributors “as is” without support and without warranty as to its quality, merchantability, or fitness for a particular purpose.
