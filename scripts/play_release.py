#!/usr/bin/env python3
"""Drives a build through Google Play's tracks: promote, roll out, halt, show.

Play Console is a browser, and nothing in this repo could reach it, so step 4
of RELEASING.md ("promote the build in Play Console") was a click nobody could
automate or audit. This talks to the Play Developer API instead, so promoting a
build is a logged run with a diff-able command rather than somebody's memory of
which track they clicked.

Credentials come from PLAY_SERVICE_ACCOUNT_JSON (the whole JSON key, as in CI)
or GOOGLE_APPLICATION_CREDENTIALS (a path). --dry-run needs neither: it prints
the exact requests it would send, which is how to check a command before it
touches real users.

  scripts/play_release.py show --track production
  scripts/play_release.py promote --from internal --to alpha
  scripts/play_release.py promote --from alpha --to production --fraction 0.1
  scripts/play_release.py rollout --track production --fraction 0.5
  scripts/play_release.py rollout --track production --fraction 1
  scripts/play_release.py halt --track production

A rollout to everyone is `--fraction 1`, which Play records as "completed"; any
fraction below 1 is an "inProgress" staged rollout that `halt` can stop. The
default for a promotion to production is a tenth, because the first few hours
of real installs are the only test that hasn't already been run by the time a
build gets this far.
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

PACKAGE = 'com.rinserepeatlabs.timeflow'
API = 'https://androidpublisher.googleapis.com/androidpublisher/v3'
SCOPE = 'https://www.googleapis.com/auth/androidpublisher'
TRACKS = ('internal', 'alpha', 'beta', 'production')
WHATSNEW = 'distribution/whatsnew/whatsnew-en-US'

# Play's own language tag for the "What's new" text we keep in the repo.
LANGUAGE = 'en-US'


def token():
    """An access token from the service account key.

    Imported here rather than at the top so --dry-run works on a machine
    without google-auth, which is the whole point of --dry-run.
    """
    try:
        from google.auth.transport.requests import Request
        from google.oauth2 import service_account
    except ImportError as e:
        sys.exit(f'this needs google-auth and requests to sign in to Play ({e}): '
                 'pip install google-auth requests (or pass --dry-run, which '
                 'signs in to nothing)')

    raw = os.environ.get('PLAY_SERVICE_ACCOUNT_JSON', '').strip()
    if raw:
        info = json.loads(raw)
        creds = service_account.Credentials.from_service_account_info(
            info, scopes=[SCOPE])
    else:
        path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS', '')
        if not path:
            sys.exit('no PLAY_SERVICE_ACCOUNT_JSON and no '
                     'GOOGLE_APPLICATION_CREDENTIALS; see docs/PLAY_STORE.md')
        creds = service_account.Credentials.from_service_account_file(
            path, scopes=[SCOPE])
    creds.refresh(Request())
    return creds.token


class Play:
    """The handful of Play endpoints a release needs.

    Every change goes inside an "edit", which is a transaction: nothing is
    visible to anyone until commit, and an abandoned edit changes nothing. That
    is what makes a failed run safe to simply re-run.
    """

    def __init__(self, dry_run):
        self.dry_run = dry_run
        self._token = None
        self.edit = None

    def call(self, method, path, body=None):
        url = f'{API}/applications/{PACKAGE}{path}'
        if self.dry_run:
            print(f'{method} {url}')
            if body is not None:
                print(json.dumps(body, indent=2))
            return {}
        if self._token is None:
            self._token = token()
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(url, data=data, method=method, headers={
            'Authorization': f'Bearer {self._token}',
            'Content-Type': 'application/json',
        })
        try:
            with urllib.request.urlopen(req) as r:
                return json.loads(r.read() or b'{}')
        except urllib.error.HTTPError as e:
            # Play's message says which field it objected to; the status alone
            # never does.
            sys.exit(f'Play refused {method} {path}: {e.code}\n'
                     f'{e.read().decode(errors="replace")}')

    def open_edit(self):
        self.edit = self.call('POST', '/edits').get('id', 'DRY-RUN-EDIT')
        return self.edit

    def commit(self):
        self.call('POST', f'/edits/{self.edit}:commit')

    def get_track(self, track):
        return self.call('GET', f'/edits/{self.edit}/tracks/{track}')

    def put_track(self, track, release):
        return self.call('PUT', f'/edits/{self.edit}/tracks/{track}',
                         {'track': track, 'releases': [release]})


def release_notes():
    """The "What's new" text, so a promotion carries it like CI's upload does."""
    try:
        with open(WHATSNEW, encoding='utf-8') as f:
            text = f.read().strip()
    except OSError:
        return None
    return [{'language': LANGUAGE, 'text': text}] if text else None


def staged(fraction):
    """Play's status and userFraction for a rollout of [fraction] of users."""
    if fraction >= 1:
        return 'completed', None
    return 'inProgress', fraction


def version_codes(play, track, wanted):
    """The build to act on: the one asked for, or the newest on [track]."""
    if wanted:
        return [int(wanted)]
    if play.dry_run:
        return ['<newest on %s>' % track]
    releases = play.get_track(track).get('releases') or []
    codes = [int(c) for r in releases for c in (r.get('versionCodes') or [])]
    if not codes:
        sys.exit(f'nothing on the {track} track to act on')
    return [max(codes)]


def release_body(codes, fraction, notes):
    status, user_fraction = staged(fraction)
    release = {'versionCodes': codes, 'status': status}
    if user_fraction is not None:
        release['userFraction'] = user_fraction
    if notes:
        release['releaseNotes'] = notes
    return release


def cmd_show(play, args):
    play.open_edit()
    for track in ([args.track] if args.track else TRACKS):
        data = play.get_track(track)
        releases = data.get('releases') or []
        if not releases:
            print(f'{track}: nothing')
        for r in releases:
            share = r.get('userFraction')
            share = f" to {round(share * 100)}% of users" if share else ''
            print(f"{track}: {','.join(str(c) for c in r.get('versionCodes', []))} "
                  f"{r.get('status', '?')}{share}")
    # Nothing was changed, so the edit is left to expire rather than committed.


def cmd_promote(play, args):
    play.open_edit()
    codes = version_codes(play, getattr(args, 'from'), args.version_code)
    play.put_track(args.to, release_body(codes, args.fraction, release_notes()))
    play.commit()
    status, _ = staged(args.fraction)
    print(f"promoted {codes} from {getattr(args, 'from')} to {args.to} "
          f"({status}{'' if args.fraction >= 1 else f', {args.fraction}'})")


def cmd_rollout(play, args):
    play.open_edit()
    codes = version_codes(play, args.track, args.version_code)
    play.put_track(args.track, release_body(codes, args.fraction, None))
    play.commit()
    print(f'{args.track}: {codes} now at '
          f"{'everyone' if args.fraction >= 1 else args.fraction}")


def cmd_halt(play, args):
    play.open_edit()
    codes = version_codes(play, args.track, args.version_code)
    release = {'versionCodes': codes, 'status': 'halted'}
    play.put_track(args.track, release)
    play.commit()
    print(f'{args.track}: {codes} halted; no new users will get it')


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--dry-run', action='store_true',
                   help='print the requests instead of sending them')
    subs = p.add_subparsers(dest='command', required=True)

    show = subs.add_parser('show', help='what is on each track')
    show.add_argument('--track', choices=TRACKS)
    show.set_defaults(func=cmd_show)

    promote = subs.add_parser('promote', help='move a build to another track')
    promote.add_argument('--from', required=True, choices=TRACKS)
    promote.add_argument('--to', required=True, choices=TRACKS)
    promote.add_argument('--fraction', type=float, default=None,
                         help='share of users, 0-1 (default: 0.1 to production, '
                              'everyone otherwise)')
    promote.add_argument('--version-code')
    promote.set_defaults(func=cmd_promote)

    rollout = subs.add_parser('rollout', help='widen a staged rollout')
    rollout.add_argument('--track', default='production', choices=TRACKS)
    rollout.add_argument('--fraction', type=float, required=True)
    rollout.add_argument('--version-code')
    rollout.set_defaults(func=cmd_rollout)

    halt = subs.add_parser('halt', help='stop a rollout reaching more users')
    halt.add_argument('--track', default='production', choices=TRACKS)
    halt.add_argument('--version-code')
    halt.set_defaults(func=cmd_halt)

    args = p.parse_args()
    if getattr(args, 'fraction', None) is None and args.command == 'promote':
        # A test track is all-or-nothing in practice; production is where a
        # tenth first, and a look at the crash rate, is worth the extra step.
        args.fraction = 0.1 if args.to == 'production' else 1.0
    if getattr(args, 'fraction', None) is not None and not 0 < args.fraction <= 1:
        sys.exit('--fraction must be more than 0 and at most 1')
    args.func(Play(args.dry_run), args)


if __name__ == '__main__':
    main()
