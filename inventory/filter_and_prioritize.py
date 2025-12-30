#!/usr/bin/env python3
"""
Filter inventory-credentials.csv for actionable credential types in target repos and prioritize by expiry.
"""
import csv
from datetime import datetime
import sys

IN_CSV = 'inventory-credentials.csv'
OUT_CSV = 'inventory-credentials-prioritized-key.csv'

TARGET_REPOS = set([
    'modulo-squares','vehicle-vitals','wishlist-wizard',
    'modulo-squares-actions-runner','vehicle-vitals-actions-runner','wishlist-wizard-actions-runner','nelson-grey'
])

KEY_TYPES = set(['p12','mobileprovision','p8','firebase-service-account','github-app-key','plist'])

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
        t = (r.get('type') or '').strip()
        if t not in KEY_TYPES:
            # allow p12 even if type other
            if not r.get('filename','').lower().endswith(('.p12','.pfx','.p8','.mobileprovision')):
                continue
        expiry = (r.get('expiry') or '').strip()
        dt = try_parse(expiry)
        filtered.append((dt, r))

    # Sort: items with parsed dates first by date, then items without date at the end
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
    for dt, r in out_rows[:20]:
        print((dt.isoformat() if dt else 'NO_DATE'), r.get('repo'), r.get('filename'), r.get('path'))

if __name__ == '__main__':
    main()
