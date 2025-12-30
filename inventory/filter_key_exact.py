#!/usr/bin/env python3
"""
Filter inventory-credentials.csv for exact credential filename patterns and prioritize by expiry.
"""
import csv
from datetime import datetime
import sys

IN_CSV = 'inventory-credentials.csv'
OUT_CSV = 'inventory-credentials-prioritized-key-exact.csv'

TARGET_REPOS = set([
    'modulo-squares','vehicle-vitals','wishlist-wizard',
    'modulo-squares-actions-runner','vehicle-vitals-actions-runner','wishlist-wizard-actions-runner','nelson-grey'
])

PATTERNS = [
    lambda fn: fn.lower().endswith('.p12'),
    lambda fn: fn.lower().endswith('.pfx'),
    lambda fn: fn.lower().endswith('.p8'),
    lambda fn: fn.lower().endswith('.mobileprovision'),
    lambda fn: fn.lower().startswith('firebase-service-account-') and fn.lower().endswith('.json'),
    lambda fn: fn.lower() == '.github-app-private-key.pem',
    lambda fn: 'runner-token-refresh' in fn.lower() or 'runner-token' in fn.lower(),
    lambda fn: fn.lower().endswith('.pem') and '/certs/' in fn.lower(),
]

DATE_FORMATS = [
    '%b %d %H:%M:%S %Y %Z',
    '%b %d %H:%M:%S %Y',
    '%Y-%m-%dT%H:%M:%SZ',
    '%Y-%m-%d %H:%M:%S %Z',
    '%Y-%m-%d %H:%M:%S',
    '%Y-%m-%d',
    '%Y-%m-%dT%H:%M:%S%z',
]


def try_parse(s):
    if not s:
        return None
    s = s.strip()
    for fmt in DATE_FORMATS:
        try:
            return datetime.strptime(s, fmt)
        except Exception:
            pass
    try:
        from email.utils import parsedate_to_datetime
        return parsedate_to_datetime(s)
    except Exception:
        return None


def matches(filename):
    for p in PATTERNS:
        try:
            if p(filename):
                return True
        except Exception:
            pass
    return False


def main():
    try:
        with open(IN_CSV, newline='') as f:
            rows = list(csv.DictReader(f))
    except FileNotFoundError:
        print('Missing', IN_CSV, file=sys.stderr)
        sys.exit(1)

    filtered = []
    for r in rows:
        repo = r.get('repo','')
        if repo not in TARGET_REPOS:
            continue
        filename = r.get('filename','')
        if not matches(filename):
            # also check path for certs folder
            path = r.get('path','')
            if '/certs/' not in path.lower():
                continue
        expiry = (r.get('expiry') or '').strip()
        dt = try_parse(expiry)
        filtered.append((dt, r))

    parsed = [x for x in filtered if x[0] is not None]
    unparsed = [x for x in filtered if x[0] is None]
    parsed.sort(key=lambda x: x[0])
    out_rows = parsed + unparsed

    with open(OUT_CSV, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['expiry_iso','repo','path','filename','type','notes'])
        for dt, r in out_rows:
            writer.writerow([dt.isoformat() if dt else '', r.get('repo',''), r.get('path',''), r.get('filename',''), r.get('type',''), r.get('notes','')])

    print('Wrote', OUT_CSV)
    print('\nTop items:')
    for dt, r in out_rows[:50]:
        print((dt.isoformat() if dt else 'NO_DATE'), r.get('repo'), r.get('filename'), r.get('path'))

if __name__ == '__main__':
    main()
