# TestFlight Deployment Verification Guide

## Overview
This guide confirms your iOS/TestFlight CI/CD is properly configured after the environment variable mapping fix.

## Step 1: Verify GitHub Secrets (Per Repository)

Each of your three app repositories needs these secrets configured:

### Required Secrets (Set in GitHub Settings → Secrets and variables → Actions)

```
✅ APP_STORE_CONNECT_KEY_ID
   - Your ASC API Key ID (from App Store Connect)
   - Format: 9 character code (e.g., ABC123XYZ)
   - Where to find: https://appstoreconnect.apple.com/access/api → Keys

✅ APP_STORE_CONNECT_ISSUER_ID
   - Your ASC Issuer ID
   - Format: UUID (e.g., 12345678-1234-1234-1234-123456789012)
   - Where to find: Same page as Key ID

✅ APP_STORE_CONNECT_KEY
   - Your ASC Private Key (.p8 file contents)
   - Format: Starts with "-----BEGIN PRIVATE KEY-----"
   - Where to find: Downloaded when you created the API key
   - ⚠️ CRITICAL: If lost, you must delete the key and create a new one
   - ⚠️ NEVER commit this to git

✅ KEYCHAIN_PASSWORD
   - Password for ephemeral Fastlane keychain (any secure password)
   - Used only during CI/CD, doesn't need to match your Mac's keychain
   - Recommendation: Use a strong random value, store securely in GitHub

✅ MATCH_GIT_PASSWORD
   - GitHub Personal Access Token (PAT) for certificate repository
   - Repository: nelson-grey (where certificates are stored)
   - Required permissions: repo (full control of private repos)
   - Link: https://github.com/settings/tokens

✅ MATCH_GIT_URL
   - Git URL to certificate repository
   - Format: https://github.com/mnelson3/nelson-grey.git
   - Or: git@github.com:mnelson3/nelson-grey.git

✅ MATCH_GIT_BRANCH
   - Branch in certificate repository where match certificates are stored
   - Default: main
```

### Quick Verification Script

For each app repository (modulo-squares, vehicle-vitals, wishlist-wizard), run:

```bash
# Check if secrets are configured
# Replace REPO with your repo path, e.g., modulo-squares

cd /Users/marknelson/Circus/Repositories/REPO

# This shows if GitHub CLI can see the secrets (requires authentication)
gh secret list

# Expected output should show:
# APP_STORE_CONNECT_KEY_ID    
# APP_STORE_CONNECT_ISSUER_ID 
# APP_STORE_CONNECT_KEY       
# KEYCHAIN_PASSWORD           
# MATCH_GIT_PASSWORD          
# MATCH_GIT_URL               
# MATCH_GIT_BRANCH            
```

## Step 2: Verify Workflow Configuration

### Check Master Pipeline Calls Reusable iOS Workflow

**File**: `.github/workflows/master-pipeline.yml` in each app repo

Look for this section (should exist):

```yaml
build-ios:
  name: Build iOS App
  needs: load-config
  if: |
    needs.load-config.outputs.ios_enabled == 'true' &&
    (needs.load-config.outputs.trigger_context == 'build_all' ||
     needs.load-config.outputs.trigger_context == 'build_and_deploy')
  uses: mnelson3/nelson-grey/.github/workflows/ios-build.yml@main
  with:
    project_name: ${{ needs.load-config.outputs.project_name }}
    release_type: ${{ needs.load-config.outputs.trigger_context == 'build_and_deploy' && 'testflight' || 'build_only' }}
    release_notes: "..."
  secrets:
    app_store_connect_key_id: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
    app_store_connect_issuer_id: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
    app_store_connect_key: ${{ secrets.APP_STORE_CONNECT_KEY }}
    match_git_password: ${{ secrets.MATCH_GIT_PASSWORD }}
    keychain_password: ${{ secrets.KEYCHAIN_PASSWORD }}
    match_git_url: ${{ secrets.MATCH_GIT_URL }}
    match_git_branch: ${{ secrets.MATCH_GIT_BRANCH }}
```

### Check Fastfile Has Beta Lane

**File**: `packages/mobile/ios/fastlane/Fastfile` in each app repo

Verify `beta` lane exists:

```bash
grep -n "lane :beta" packages/mobile/ios/fastlane/Fastfile
# Expected: Should show line number with "lane :beta"
```

## Step 3: Test the iOS/TestFlight Workflow

### Option A: Manual Run via GitHub UI (Recommended for Initial Test)

1. Go to your app repository → Actions
2. Select "Master CI/CD Pipeline" workflow
3. Click "Run workflow" button
4. Select dropdown options:
   - **Action**: `build_and_deploy`
   - **Environment**: `development` or `staging`
   - **Verbose**: ✓ (check for verbose output)
5. Click "Run workflow"
6. Watch the build progress in real-time

### Option B: Command Line (Advanced)

```bash
cd /Users/marknelson/Circus/Repositories/modulo-squares

# Trigger workflow
gh workflow run master-pipeline.yml \
  -f action=build_and_deploy \
  -f environment=development \
  -f verbose=true

# Watch execution
gh run watch $(gh run list -w master-pipeline.yml -L 1 --json databaseId --jq '.[0].databaseId')
```

## Step 4: Interpret Workflow Results

### ✅ Success indicators:

1. "Build iOS App" job completes successfully
2. Output shows:
   ```
   📤 Uploading IPA to TestFlight...
   ✅ IPA uploaded to TestFlight successfully
   ```
3. No errors in "Setup App Store Connect Authentication" step
4. Fastlane `beta` lane execution completes

### ❌ Common failure points:

| Error | Cause | Fix |
|-------|-------|-----|
| `Missing APP_STORE_CONNECT_KEY` | Secret not set | Add to GitHub Settings → Secrets |
| `Could not locate the provided keychain` | Ephemeral keychain corrupted | Check KEYCHAIN_PASSWORD is set |
| `No matching provisioning profiles found` | Match certificates not synced | Run `match appstore` locally first |
| `timeout waiting for build processing` | Apple's servers slow | This is normal - upload succeeded anyway |
| `Failed to unlock keychain` | Wrong KEYCHAIN_PASSWORD | Verify password in GitHub secrets |

## Step 5: Verify Build in TestFlight

After successful workflow completion:

1. Go to [App Store Connect → TestFlight](https://appstoreconnect.apple.com/apps/)
2. Select your app (e.g., Modulo Squares)
3. Look for your build in:
   - **Builds** tab → should show new build uploaded
   - Status: "Processing" (takes 5-15 minutes) → "Ready to Test"
4. Click build to see:
   - iOS version and build number
   - Upload date and time
   - Build status

## Step 6: What to Do If Still Failing

### Enable maximally verbose GitHub Actions output:

Add this step to ios-build.yml after the "Build iOS App" step:

```yaml
- name: Debug Output
  if: failure()
  run: |
    echo "=== Environment Variables (Public Only) ==="
    env | grep -E "APP_STORE_CONNECT|MATCH|GITHUB|RUNNER" | grep -v "SECRET\|PASSWORD\|KEY" | sort
    echo ""
    echo "=== Available Fastlane Lanes ==="
    cd packages/mobile/ios
    fastlane list
    echo ""
    echo "=== Full Fastlane Version ==="
    fastlane --version
```

Then re-run workflow and check "Debug Output" step for exact error.

### Common secrets issues to debug:

```bash
# Check if secret value contains special characters requiring escaping
echo "${{ secrets.APP_STORE_CONNECT_KEY }}" | head -c 50

# Verify JSON format isn't corrupted
echo "${{ secrets.APP_STORE_CONNECT_KEY }}" | jq . 2>&1

# Check for null bytes (common GitHub Actions artifact issue)
echo "${{ secrets.APP_STORE_CONNECT_KEY }}" | od -c | head -20
```

## Summary: Expected Workflow After Fix

```
GitHub Trigger (build_and_deploy on main)
    ↓
Master CI/CD Pipeline Job (load-config)
    ├─ Load project manifest
    └─ Determine TestFlight mode
        ↓
    Build iOS App Job (uses reusable ios-build.yml)
        ├─ Environment check
        ├─ Git config fix
        ├─ Flutter install
        ├─ Ruby/Fastlane setup
        ├─ Create ephemeral keychain
        ├─ Sync certificates with Match
        ├─ Build & sign app with gym
        ├─ Upload IPA to TestFlight ← THIS WAS FAILING
        └─ Cleanup
            ↓
        ✅ IPA appears in App Store Connect TestFlight in 5-15 minutes
```

## The Fix Applied

**File**: `/nelson-grey/.github/workflows/ios-build.yml`

**Change**: Standardized on `APP_STORE_CONNECT_*` environment variable naming convention. Removed all legacy `ASC_*` references from workflows and Fastfiles.

```yaml
# Standardized naming (used everywhere now)
env:
  APP_STORE_CONNECT_KEY_ID: ${{ secrets.app_store_connect_key_id }}
  APP_STORE_CONNECT_ISSUER_ID: ${{ secrets.app_store_connect_issuer_id }}
  APP_STORE_CONNECT_KEY: ${{ secrets.app_store_connect_key }}
```

This ensures consistent credential passing from GitHub Actions to Fastlane across all three app repositories.

---

## Next Steps

1. ✅ Verify all secrets are configured (Step 1)
2. ⏭️ Run a test workflow on development environment
3. ⏭️ Check TestFlight for build appearance
4. ⏭️ Test on staging environment
5. ⏭️ Promote to production

**Questions?** Check docs/TROUBLESHOOTING.md for detailed error solutions.
