# Secrets Mapping Guide - Phase 5b

## Problem
Workflows require standardized names: `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY`.

## Solution
Ensure environment variables in each repo's `load-config` job use the standardized names.

---

## Implementation per Repository

### modulo-squares
**Existing secrets** → **New workflow expects**:
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY`
- `FIREBASE_TOKEN` ✅ (matches)
- `MATCH_PASSWORD` ✅ (matches)
- `MATCH_GIT_URL` ✅ (matches)
- `MATCH_GIT_BRANCH` ⚠️ (not found; needs to be set or hardcoded)

**Action**: Update `master-pipeline.yml` load-config step to map secrets:
```yaml
env:
  APP_STORE_CONNECT_KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
  APP_STORE_CONNECT_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
  APP_STORE_CONNECT_KEY: ${{ secrets.APP_STORE_CONNECT_KEY }}
  FIREBASE_PROJECT_DEV: ${{ secrets.FIREBASE_PROJECT_DEVELOPMENT || 'modulo-squares-dev' }}
  FIREBASE_PROJECT_STAGING: ${{ secrets.FIREBASE_PROJECT_STAGING || 'modulo-squares-staging' }}
  FIREBASE_PROJECT_PROD: ${{ secrets.FIREBASE_PROJECT_PRODUCTION || 'modulo-squares-prod' }}
  MATCH_GIT_BRANCH: main
```

---

### vehicle-vitals
**Existing secrets** → **New workflow expects**:
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY`
- `FIREBASE_TOKEN` ✅ (matches)
- `MATCH_PASSWORD` ✅ (matches)
- `MATCH_GIT_URL` ✅ (matches)
- `MATCH_GIT_BRANCH` ⚠️ (not found)
- Android keystore: `ANDROID_KEYSTORE_PATH`, `ANDROID_KEY_ALIAS`, passwords missing

**Action**: Update `master-pipeline.yml` load-config to map secrets and set Android credentials.

---

### wishlist-wizard
**Existing secrets** → **New workflow expects**:
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY`
- `FIREBASE_TOKEN` ✅ (matches)
- `CHROME_CLIENT_ID` ✅ (matches)
- `CHROME_CLIENT_SECRET` ✅ (matches)
- `CHROME_EXTENSION_ID` ✅ (matches)
- `CHROME_REFRESH_TOKEN` ⚠️ (not found)
- `FIREBASE_PROJECT_DEVELOPMENT` → `FIREBASE_PROJECT_DEV`
- `FIREBASE_PROJECT_STAGING` ✅ (matches)
- `FIREBASE_PROJECT_PRODUCTION` → `FIREBASE_PROJECT_PROD`
- `MATCH_PASSWORD` ✅ (matches)
- `MATCH_GIT_URL` ✅ (matches)
- `MATCH_GIT_BRANCH` ⚠️ (not found)

**Action**: Update `master-pipeline.yml` load-config to map and alias Firebase project secrets.

---

### stream-control
**Existing secrets** → **New workflow expects**:
- Minimal; only needs `FIREBASE_TOKEN` (optional)

**Action**: No mapping needed; workflow uses ubuntu-latest runners.

---

## Quick Fix: Update master-pipeline.yml in Each Repo

Insert env block in `load-config` job after `runs-on`:

```yaml
jobs:
  load-config:
    name: Load Project Configuration
    runs-on: self-hosted
    env:
      # Standard App Store Connect secrets
      APP_STORE_CONNECT_KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID || '' }}
      APP_STORE_CONNECT_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID || '' }}
      APP_STORE_CONNECT_KEY: ${{ secrets.APP_STORE_CONNECT_KEY || '' }}
      FIREBASE_PROJECT_DEV: ${{ secrets.FIREBASE_PROJECT_DEVELOPMENT || secrets.FIREBASE_PROJECT_DEV || '' }}
      FIREBASE_PROJECT_STAGING: ${{ secrets.FIREBASE_PROJECT_STAGING || '' }}
      FIREBASE_PROJECT_PROD: ${{ secrets.FIREBASE_PROJECT_PRODUCTION || secrets.FIREBASE_PROJECT_PROD || '' }}
      MATCH_GIT_BRANCH: ${{ secrets.MATCH_GIT_BRANCH || 'main' }}
    outputs:
      ...
```

Then pass these env vars to reusable workflows via `secrets:`.

---

## Missing Secrets to Add

**All Flutter projects** need:
1. `MATCH_GIT_BRANCH` - Set to `main` or actual branch name
2. `ANDROID_KEYSTORE_PATH` - Path to .jks file (e.g., `/home/runner/keystore.jks`)
3. `ANDROID_KEY_ALIAS` - Alias in keystore
4. `ANDROID_KEYSTORE_PASSWORD` - Keystore password
5. `ANDROID_KEY_PASSWORD` - Key password

**wishlist-wizard** needs:
- `CHROME_REFRESH_TOKEN` - Google OAuth refresh token

---

## Recommended Action Plan

1. ✅ **Done**: YAML validation (all 4 repos)
2. **Next**: Update each master-pipeline.yml to add env block for secret mapping
3. **Then**: Trigger workflow_dispatch: build_all (test_all first to catch errors)
4. **Finally**: Archive legacy workflows once new pipeline green
