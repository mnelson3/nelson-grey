# Phase 5 Validation & Secrets Checklist

**Status**: ✅ All 4 manifests valid YAML

## Required Secrets by Project

### modulo-squares (Flutter iOS/Android + Web + Functions)
**iOS Build**:
- `APP_STORE_CONNECT_KEY_ID` - App Store Connect key ID
- `APP_STORE_CONNECT_ISSUER_ID` - App Store Connect issuer ID  
- `APP_STORE_CONNECT_KEY` - App Store Connect private key (PEM format or base64)
- `MATCH_PASSWORD` - Fastlane match password for certificate repo
- `MATCH_GIT_URL` - Git URL to match certificates repo
- `MATCH_GIT_BRANCH` - Git branch for match certificates

**Web/Firebase**:
- `FIREBASE_TOKEN` - Firebase CLI authentication token
- `FIREBASE_PROJECT_DEV` - Firebase project ID for development
- `FIREBASE_PROJECT_STAGING` - Firebase project ID for staging
- `FIREBASE_PROJECT_PROD` - Firebase project ID for production

**Android** (optional, remove if empty):
- `ANDROID_KEYSTORE_PATH` - Path to Android keystore file
- `ANDROID_KEY_ALIAS` - Key alias in Android keystore
- `ANDROID_KEYSTORE_PASSWORD` - Keystore password
- `ANDROID_KEY_PASSWORD` - Key password

**Status**: Check GitHub repo settings → Secrets and variables → Actions

---

### vehicle-vitals (Flutter iOS/Android + React Web + Functions + DataConnect)
**Same as modulo-squares** plus:
- `ANDROID_KEYSTORE_PATH` (vehicle-vitals-key.jks exists in repo root)
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`

**Status**: Check GitHub repo settings

---

### wishlist-wizard (Flutter iOS/Android + React Web + Chrome Extension + Functions)
**iOS/Android/Web**: Same as modulo-squares

**Chrome Extension**:
- `CHROME_EXTENSION_ID` - Chrome Web Store extension ID
- `CHROME_CLIENT_ID` - Google OAuth client ID
- `CHROME_CLIENT_SECRET` - Google OAuth client secret
- `CHROME_REFRESH_TOKEN` - Google OAuth refresh token

**Status**: Check GitHub repo settings

---

### stream-control (Expo Mobile + Next.js Web + Node API)
**Minimal** (uses ubuntu-latest runners):
- `FIREBASE_TOKEN` (optional, for Firebase functions)

**Status**: Check GitHub repo settings

---

## Validation Steps Completed

- [x] YAML syntax validation (all 4 manifests)
- [x] Secret extraction from reusable workflows
- [x] Bundle ID/App ID verification
- [x] Build command validation

## Next Steps (Phase 5b)

1. **Verify secrets are set** in each GitHub repo (Settings → Secrets and variables → Actions)
2. **Trigger workflow_dispatch: build_all** on each repo via GitHub UI or CLI
3. **Monitor build results** in GitHub Actions
4. **Archive legacy workflows** once new pipeline confirmed working
5. **Enable branch protection rules** requiring new pipeline status checks

## Quick Secret Verification

Run per repo:
```bash
# modulo-squares
gh secret list -R mnelson3/modulo-squares

# vehicle-vitals  
gh secret list -R mnelson3/vehicle-vitals

# wishlist-wizard
gh secret list -R mnelson3/wishlist-wizard

# stream-control
gh secret list -R mnelson3/stream-control
```

Replace with actual values if missing.
