# restickler

A wrapper for [restic](https://restic.net/) that supervises back up, test restore, forget, prune, and check. Designed for macOS but it should also work on Linux.

## Features

- Run back up and maintenance functions (forget, prune, and check) on a minimal interval schedule. E.g., schedule back up to every 3 hours with `restickler -b 3`, and prune every 3 days with `restickler -p 72`.
- Skip if there has been no user activity since last back up (`-A`), if on battery power (`-B`), if tethered to an iOS hotspot (`-H`), or if internet is unreliable (`-I`) (macOS only).
- Limit upload and download speed as a percentage of available bandwidth, e.g., `-u 50% -d 50%` (macOS only).
- Test restoring a unique “canary” file after every back up (for $HOME only).
- Receive notifications of errors and back up delays via [Healthchecks.io](https://healthchecks.io/) (optional).

## Install

1. Install prerequisites with [Homebrew](https://brew.sh/ "The Missing Package Manager for macOS"):
```bash
brew install restic jq
```
2. Install the `restickler` script in `~/bin/` and its config files in `~/etc/restickler/`:
```bash
mkdir -p ~/{bin,etc/restickler}
curl -L -o ~/bin/restickler https://raw.githubusercontent.com/quinncomendant/restickler/master/bin/restickler
curl -L -o ~/etc/restickler/env https://raw.githubusercontent.com/quinncomendant/restickler/master/etc/restickler/env
curl -L -o ~/etc/restickler/exclude/restickler.txt https://raw.githubusercontent.com/quinncomendant/restickler/master/etc/restickler/exclude/restickler.txt
chmod 755 ~/bin/restickler
```

## Set up

1. [Prepare your back up repository](https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html) (GCP’s [Coldline Storage](https://cloud.google.com/storage/docs/storage-classes#coldline) is a great choice)
2. Initialize the backup destination, e.g., if using GCP Storage: `restic -r gs://[your bucket name]:/ init`
3. Configure credentials and repository in `~/etc/restickler/env`
4. Configure excluded paths in `~/etc/restickler/exclude/restickler.txt`
5. Test your configuration with a dry-run: `restickler -n $HOME`
6. Back up your home directory: `restickler $HOME`
7. Automatically back up hourly by adding this to `crontab -e`:
```cron
PATH=/Users/[your username]/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
* * * * * restickler -vvABHI -d 75\% -u 75\% -b 1 $HOME >/dev/null
```
(For restic to have permission to access your files you may need to give `cron` [Full Disk Access](https://send.strangecode.com/f/screen-shot-2022-04-10-at-13-25-23.png) in *System Preferences → Security & Privacy → Privacy → Full Disk Access → (click + and select `/usr/sbin/cron`)*)

## Update

Get the latest version of `restic` and `restickler` by running their self-update commands:
```bash
restic self-update
restickler --self-update
```

## Usage

Run `restickler -h` to print this usage message:

```
USAGE

  restickler [OPTIONS] SOURCE [SOURCE…]

Back up SOURCE to the restic repository configured in `~/etc/restickler/env`.

OPTIONS

  -b HOURS       Min interval between back up operations (currently every 0 hours).
  -c HOURS       Min interval between check operations (currently every 168 hours).
  -d MBPS|%      Limit download speed in Mb/s or as a percentage of available bandwidth, e.g., `-d 50%`.
  -e FILE        File containing back up exclusion rules, used as --exclude-file=FILE.
  -f HOURS       Min interval between forget operations (currently every 24 hours).
  -h             Display this help message.
  -n             Dry run: print the expected outcome to the screen; don’t actually do anything.
  -p HOURS       Min interval between prune operations (currently every 240 hours).
  -q             Do not output comprehensive progress report.
  -u MBPS|%      Limit upload speed in Mb/s or as a percentage of available bandwidth, e.g., `-u 50%`.
  -v             Display verbose output (-vv or -vvv to list uploaded files).
  -A             Abort if there has been no user activity since last back up.
  -B             Abort if on battery power.
  -H             Abort if connected to an iOS hotspot.
  -I             Abort if internet is unreliable.
  -V             Print version information.
  --self-update  Download the replace restickler with the latest release from GitHub.

restickler runs the following commands to maintain the full lifecycle of a healthy repository:

  1. `restic backup` (every 0 hours or as specified by -b)
  2. `restic restore` (test of a single “canary” file at `~/etc/restickler/canary/[timestamp]`)
  3. `restic forget` (every 24 hours or as specified by -f)
  4. `restic prune` (every 240 hours or as specified by -p)
  5. `restic check` (every 168 hours or as specified by -c)

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

LOGS

Activity is logged to `~/var/restickler/log`. If run with `-v`, a list of uploaded files is included.

EXAMPLES

Back up the home directory:

  restickler $HOME

Back up home, print files as they upload, limited to 50% of the available bandwidth:

  restickler -vv -d 50% -u 50% $HOME

  Force back up, forget, prune, and check to run by setting intervals to 0 (removing the
  `~/var/restickler/last-*-time` files would also reset the interval timer):

  restickler -b 0 -f 0 -p 0 -c 0 $HOME

A sane configuration for crontab (cron needs % to be escaped):

  * * * * * restickler -vvABHI -d 75\% -u 75\% -b 1 $HOME >/dev/null

Back up multiple paths, with a custom excludes file:

  restickler -e $HOME/etc/restickler/exclude/library.txt $HOME/Library/Application\ Support/{MailMate,TextMate}

Pause restickler:

    mkdir /tmp/restickler/lock

Unpause restickler (or restart computer, which clears /tmp/ files):

    rm -r /tmp/restickler/lock

```
