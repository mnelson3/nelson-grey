#!/usr/bin/env python3
"""
Generate a rotation plan CSV from filtered prioritized CSV using simple heuristics.
"""
import csv
from datetime import datetime, timedelta

IN = 'inventory-credentials-prioritized-key-exact.csv'
OUT = 'rotation-plan.csv'

now = datetime.now()

def parse_iso(s):
    if not s:
        return None
    try:
        return datetime.fromisoformat(s)
    except Exception:
        return None

rows = []
with open(IN, newline='') as f:
    reader = csv.DictReader(f)
    for r in reader:
        expiry = parse_iso(r.get('expiry_iso',''))
        if expiry:
            delta = (expiry - now).days
            if delta < 0:
                priority = 'Immediate'
            elif delta <= 365:
                priority = 'High'
            elif delta <= 3*365:
                priority = 'Medium'
            else:
                priority = 'Low'
        else:
            priority = 'High'
            delta = None
        action = 'inspect and centralize'
        fn = r.get('filename','').lower()
        if fn.endswith('.p8'):
            action = 'move to central secure store; restrict access'
        elif fn.endswith('.p12') or fn.endswith('.pfx'):
            action = 'inspect, extract expiry (need password), store encrypted'
        elif fn.endswith('.mobileprovision'):
            action = 'verify provisioning profile, associate with cert'
        elif 'firebase-service-account' in fn:
            action = 'rotate key if stale; store in secret manager'
        elif 'runner-token-refresh' in fn:
            action = 'migrate token refresh into runner-manager service'

        rows.append({
            'repo': r.get('repo',''),
            'path': r.get('path',''),
            'filename': r.get('filename',''),
            'expiry': r.get('expiry_iso',''),
            'priority': priority,
            'days_until_expiry': '' if delta is None else str(delta),
            'recommended_action': action,
        })

with open(OUT, 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['repo','path','filename','expiry','days_until_expiry','priority','recommended_action'])
    for r in rows:
        w.writerow([r['repo'], r['path'], r['filename'], r['expiry'], r['days_until_expiry'], r['priority'], r['recommended_action']])

print('Wrote', OUT)
