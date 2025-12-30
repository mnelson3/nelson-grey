#!/usr/bin/env python3
"""
Read inventory-credentials.csv, parse expiry dates, and output a prioritized CSV sorted by expiry (soonest first).
"""
import csv
from datetime import datetime
import sys

IN_CSV = 'inventory-credentials.csv'
OUT_CSV = 'inventory-credentials-prioritized.csv'

# Try multiple date formats
DATE_FORMATS = [
    '%b %d %H:%M:%S %Y %Z',   # OpenSSL like: Jul 12 12:00:00 2026 GMT
    '%b %d %H:%M:%S %Y',      # without TZ
    '%Y-%m-%dT%H:%M:%SZ',     # ISO Z
    '%Y-%m-%d %H:%M:%S %Z',   # some variants
    '%Y-%m-%d %H:%M:%S',
    '%Y-%m-%d',
    '%Y-%m-%dT%H:%M:%S%z',
]


def try_parse(s):
    if not s:
        return None
    s = s.strip()
    # Common garbage
    if s.lower() in ('', 'none', 'n/a'):
        return None
    # Try direct iso parsing
    for fmt in DATE_FORMATS:
        try:
            return datetime.strptime(s, fmt)
        except Exception:
            pass
    # Try removing timezone name
    import re
    m = re.search(r'(\w{3} \d{1,2} \d{2}:\d{2}:\d{2} \d{4})', s)
    if m:
        try:
            return datetime.strptime(m.group(1), '%b %d %H:%M:%S %Y')
        except Exception:
            pass
    # Try email.utils fallback
    try:
        from email.utils import parsedate_to_datetime
        dt = parsedate_to_datetime(s)
        return dt
    except Exception:
        pass
    return None


def main():
    try:
        with open(IN_CSV, newline='') as f:
            reader = csv.DictReader(f)
            rows = list(reader)
    except FileNotFoundError:
        print('Input CSV not found:', IN_CSV, file=sys.stderr)
        sys.exit(2)

    parsed = []
    for r in rows:
        expiry = r.get('expiry', '') or ''
        # skip notes like password-protected-or-unreadable
        if expiry.strip() == '' or expiry.strip().lower() in (
            'password-protected-or-unreadable', 'could-not-parse-expiry', 'security-cms-failed', 'not-x509-pem-or-unreadable'):
            continue
        dt = try_parse(expiry)
        if dt is None:
            # skip unparsed entries
            continue
        parsed.append((dt, r))

    parsed.sort(key=lambda x: x[0])

    # write prioritized csv
    with open(OUT_CSV, 'w', newline='') as f:
        fieldnames = ['expiry_iso', 'repo', 'path', 'filename', 'type', 'notes']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for dt, r in parsed:
            writer.writerow({
                'expiry_iso': dt.isoformat(),
                'repo': r.get('repo', ''),
                'path': r.get('path', ''),
                'filename': r.get('filename', ''),
                'type': r.get('type', ''),
                'notes': r.get('notes', ''),
            })

    # Print top 20
    print('Top 20 soonest-expiring credentials:')
    for dt, r in parsed[:20]:
        print(f"{dt.date().isoformat()}\t{r.get('repo','')}\t{r.get('filename','')}\t{r.get('path','')}")


if __name__ == '__main__':
    main()
