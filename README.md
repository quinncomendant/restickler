# restickler

A wrapper for [restic](https://restic.net/) that supervises back up, test restore, forget, prune, and check.

## Install

```bash
mkdir ~/bin
curl -L -o ~/bin/restickler https://path-to-restickler-script
chmod 755 ~/bin/restickler
```

## Update

```bash
restickler self-update
```
## Usage

Run `restickler -h` to print this usage message:

```
Usage: restickler [OPTIONS] SOURCE [SOURCE…]

restickler supervises restic to back up, test restore, forget, prune, and check.

Back up SOURCE to the restic repository configured in `~/etc/restickler/env`.

OPTIONS

  -b HOURS    Min interval between back up operations (currently every 0 hours).
  -c HOURS    Min interval between check operations (currently every 168 hours).
  -d MBPS|%   Limit download speed in Mb/s or as a percentage of available bandwidth, e.g., `-d 50%`.
  -e FILE     File containing back up exclusion rules, used as --exclude-file=FILE.
  -f HOURS    Min interval between forget operations (currently every 24 hours).
  -h          Display this help message.
  -n          Dry run: print the expected outcome to the screen; don’t actually do anything.
  -p HOURS    Min interval between prune operations (currently every 240 hours).
  -q          Do not output comprehensive progress report.
  -u MBPS|%   Limit upload speed in Mb/s or as a percentage of available bandwidth, e.g., `-u 50%`.
  -v          Display verbose output (-vv or -vvv to list uploaded files).
  -A          Abort if there has been no user activity since last back up.
  -B          Abort if on battery power.
  -H          Abort if connected to an iOS hotspot.
  -I          Abort if internet is unreliable.

restickler runs the following commands to maintain the full lifecycle of a healthy repository:

  1. `restic backup` (every 0 hours or as specified by -b)
  2. `restic restore` (test of a single “canary” file at `~/etc/restickler/canary/{DATETIME}`)
  3. `restic forget` (every 168 hours or as specified by -f)
  4. `restic prune` (every 24 hours or as specified by -p)
  5. `restic check` (every 240 hours or as specified by -c)

GETTING STARTED

  1. Configure credentials and repository in `~/etc/restickler/env` (see ENVIRONMENT VARIABLES below)
  2. Configure excluded paths in `~/etc/restickler/exclude/restickler.txt`
  3. Initialize the backup destination: `restic -r gs://backup-bucket-name:/ init`
  4. Do back up with `restickler $HOME`

About every year-or-so, when connected to fast internet, run `restic check --read-data` to verify all data.

ENVIRONMENT VARIABLES

The following environment variables must be defined in `~/etc/restickler/env`:

  RESTIC_PASSWORD_COMMAND         The shell command to obtain the repository password from.
  GOOGLE_PROJECT_ID               GCP project ID.
  GOOGLE_APPLICATION_CREDENTIALS  GCP Service Account credentials.
  RESTIC_REPOSITORY               The repository to back up to and restore from.
  HEALTHCHECKS_URL                The URL to ping for back up success or failure at Healthchecks.io (optional).

The GOOGLE_* variables can be replaced by the cloud-provider of your choice;
see https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html

EXAMPLES

Back up the home directory:

  restickler $HOME

Back up home, print files as they upload, limited to 50% of the available bandwidth:

  restickler -vv -d 50% -u 50% $HOME

Force forget, prune, and check to run by setting intervals to 0 (removing the
~/var/restickler/last-*-time files would also reset the interval timer):

  restickler -f 0 -p 0 -c 0 $HOME

A sane configuration for crontab (cron needs % to be escaped):

  0 * * * * restickler -vvABHI -d 75\% -u 75\% -b 1 -f 24 -p 168 -c 72 $HOME >/dev/null

Back up multiple paths, with a custom excludes file:

  restickler -e $HOME/etc/restickler/exclude/library.txt $HOME/Library/Application\ Support/{MailMate,TextMate}

To pause restickler (do this before editing this script in production):

    mkdir /tmp/restickler/lock

To unpause restickler (or restart computer, which clears /tmp/ files):

    rm -r /tmp/restickler/lock
```
