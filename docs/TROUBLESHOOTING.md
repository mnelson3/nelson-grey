# Comprehensive Troubleshooting Guide

**Last Updated**: January 2026  
**Focus**: Solutions for known issues and edge cases

---

## Table of Contents

1. [iOS Build Issues](#ios-build-issues)
2. [Keychain Problems](#keychain-problems)
3. [Runner Issues](#runner-issues)
4. [Firebase Deployment](#firebase-deployment)
5. [Docker Issues](#docker-issues)
6. [Secret Management](#secret-management)
7. [GitHub Actions](#github-actions)
8. [Performance](#performance)

---

## iOS Build Issues

### Issue: "Fastlane version mismatch"

**Symptoms**:
```
Error: fastlane version 2.232.0 not available
```

**Root Cause**: Fastlane doesn't release every version number. Version 2.232 doesn't exist.

**Solution**:
```bash
# Use the latest available version in the 2.230.x series
gem "fastlane", "~> 2.230"  # Automatically gets 2.230.0 or latest 2.230.x

# Or pin to exact version
gem "fastlane", "2.230.0"

# Update Gemfile
cd packages/mobile/ios
nano Gemfile  # Set to: gem "fastlane", "~> 2.230"

# Rebuild lock file
rm Gemfile.lock
bundle install
bundle exec fastlane --version  # Should show 2.230.0
```

**Prevention**: Always test version changes locally before committing:
```bash
bundle install
bundle exec fastlane --version
```

---

### Issue: "Unknown option: keychain_path"

**Symptoms**:
```
Error: Unknown option: keychain_path for action: match
```

**Root Cause**: The `keychain_path` parameter doesn't exist. Fastlane match uses `keychain_name` instead.

**Solution**:
```ruby
# WRONG (older Fastlane or misunderstanding)
match(
  keychain_path: "~/Library/Keychains/my_keychain.keychain-db"
)

# RIGHT (Fastlane 2.230.0)
match(
  keychain_name: ENV['MATCH_KEYCHAIN_NAME'],    # e.g., "fastlane_tmp_keychain"
  keychain_password: ENV['MATCH_KEYCHAIN_PASSWORD']
)
```

**Update Fastfile**:
```bash
cd packages/mobile/ios/fastlane
nano Fastfile

# Find: keychain_path: ...
# Replace with: keychain_name: ENV['MATCH_KEYCHAIN_NAME']
```

**Prevention**: Check [Fastlane documentation](https://docs.fastlane.tools/actions/match/) for your version.

---

## Keychain Problems

### Issue: "Could not locate the provided keychain"

**Symptoms**:
```
security: SecKeychainUnlock /Users/mark/Library/Keychains/fastlane_tmp_keychain.keychain-db: The specified keychain could not be found.

Could not locate the provided keychain. Tried:
    /Users/mark/Library/Keychains/fastlane_tmp_keychain-db
    /Users/mark/Library/Keychains/fastlane_tmp_keychain.keychain-db
    /Users/mark/Library/Keychains/fastlane_tmp_keychain
    /Users/mark/Library/Keychains/fastlane_tmp_keychain.keychain
    (8 total paths tried)
```

**Root Cause**: **KEYCHAIN LOCATION MISMATCH**

The ephemeral keychain script was creating keychains in `${RUNNER_TEMP}` (GitHub Actions temp directory), but Fastlane match with `keychain_name` parameter expects keychains in `~/Library/Keychains/`.

**Solution**: ✅ **ALREADY FIXED IN THIS ARCHITECTURE**

Verify the fix is in place:
```bash
grep "KC_DIR=" shared/runner-scripts/ephemeral_keychain_fastlane_fixed.sh

# Should output:
KC_DIR="$HOME/Library/Keychains"

# NOT:
KC_DIR="${RUNNER_TEMP:-/tmp}"
```

**If not fixed**, update it:
```bash
nano shared/runner-scripts/ephemeral_keychain_fastlane_fixed.sh

# Find line ~78:
# OLD: KC_DIR="${RUNNER_TEMP:-/tmp}"
# NEW: KC_DIR="$HOME/Library/Keychains"

# Then restart the workflow
```

**Why this matters**:
- Fastlane match searches for keychains in specific locations
- When using `keychain_name` parameter (newer Fastlane), it ONLY searches in `~/Library/Keychains/`
- If keychain is elsewhere, match can't find it
- Result: Certificate import fails, build fails

**Testing the fix**:
```bash
# Create test keychain
HOME=/Users/$(whoami) shared/runner-scripts/ephemeral_keychain_fastlane_fixed.sh "echo test"

# Verify it was created in correct location
ls -la ~/Library/Keychains/fastlane_tmp_keychain*

# Should show:
-rw------- user  staff  ... fastlane_tmp_keychain.keychain-db
-rw------- user  staff  ... fastlane_tmp_keychain.keychain-db-wal
-rw------- user  staff  ... fastlane_tmp_keychain.keychain-db-shm

# NOT in: /tmp/ or $RUNNER_TEMP
```

---

### Issue: "Certificate not in keychain"

**Symptoms**:
```
Error: 0 valid identities found
Error importing certificate
```

**Root Causes**:
1. P12 file is corrupted or wrong format
2. P12 password is incorrect
3. Keychain permissions are wrong
4. WWDR certificate missing

**Solutions**:

#### Check P12 File
```bash
# Verify P12 exists and is readable
ls -la ~/.private_keys/Certificates.p12

# Verify it's a valid P12
openssl pkcs12 -in ~/.private_keys/Certificates.p12 -noout -passin pass:YOUR_PASSWORD

# If openssl fails, P12 is corrupted
```

#### Import WWDR Certificate
```bash
# Apple Worldwide Developer Relations certificate
# Required for certificate validation
curl -fsSL "https://developer.apple.com/certificationauthority/AppleWWDRCA.cer" -o /tmp/WWDR.cer

# Import to login keychain
security import /tmp/WWDR.cer -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign

# Verify
security find-certificate -c "Apple Worldwide Developer Relations" ~/Library/Keychains/login.keychain-db
```

#### Check Keychain Permissions
```bash
# List keychain access
security dump-keychain ~/Library/Keychains/login.keychain-db | grep -A5 "Certificate"

# Set permissions
security set-keychain-settings ~/Library/Keychains/login.keychain-db

# Unlock keychain
security unlock-keychain -p YOUR_PASSWORD ~/Library/Keychains/login.keychain-db
```

---

### Issue: "Keychain prompt while building"

**Symptoms**: Build pauses asking "Allow codesign to use key?"

**Root Cause**: Keychain not configured to allow automatic access

**Solution**:
```bash
# Set partition list for codesign
security set-key-partition-list -S apple-tool:,apple:,codesign: \
  -k YOUR_KEYCHAIN_PASSWORD \
  ~/Library/Keychains/fastlane_tmp_keychain.keychain-db

# Or for login keychain
security set-key-partition-list -S apple-tool:,apple:,codesign: \
  -k YOUR_PASSWORD \
  ~/Library/Keychains/login.keychain-db
```

---

## Runner Issues

### Issue: "No available runner found"

**Symptoms**:
```
Requested runner not found for job
Workflow job assigned to runner: [runner-name]
Couldn't retrieve runner [runner-name]
```

**Root Causes**:
1. Runner offline
2. Runner labels don't match job requirements
3. Runner disk full
4. Runner process crashed

**Solutions**:

#### Check Runner Status
```bash
# Check if service is running
launchctl list | grep actions.runner

# Expected: something like "77  0  actions.runner.mnelson3-nelson-grey..."

# If not running, start it
cd ~/Circus/Repositories/nelson-grey/actions-runner
./svc.sh start

# Check logs
tail -f _diag/Runner_*.log
```

#### Check Runner Labels
```bash
# List configured labels
cat .runner

# Expected to show: self-hosted, macOS, ios

# If labels wrong, reconfigure:
./config.sh
# When prompted for labels, use: self-hosted,macOS,ios
```

#### Check Disk Space
```bash
# Check available disk
df -h ~

# If < 5GB, clean up:
rm -rf actions-runner/_work/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

#### Restart Runner Service
```bash
cd ~/Circus/Repositories/nelson-grey/actions-runner
./svc.sh stop
./svc.sh start

# Verify it comes online
sleep 5
gh api repos/mnelson3/modulo-squares/actions/runners | jq '.runners[] | select(.status == "online")'
```

---

### Issue: "Runner job timeout"

**Symptoms**:
```
The job running on runner [runner-name] has exceeded the maximum execution time of 360 minutes.
```

**Root Causes**:
1. Build genuinely takes > 6 hours
2. Workflow stuck (no progress for hours)
3. runner network issue

**Solutions**:

#### Increase Timeout (if build is slow)
```yaml
# In workflow YAML
jobs:
  build:
    runs-on: [self-hosted, macOS]
    timeout-minutes: 120  # Increase from default 360
```

#### Debug Stuck Build
```bash
# SSH to runner machine
ssh $(hostname)

# Check what processes are running
ps aux | grep -i build | grep -v grep

# Check system resources
top -l 2 | head -30

# If stuck, kill process
pkill -f "fastlane"
pkill -f "flutter"
```

#### Network Issues
```bash
# Check network connectivity
ping github.com

# Check DNS
nslookup github.com

# If issues, restart network
sudo dscacheutil -flushcache
```

---

## Firebase Deployment

### Issue: "Firebase authentication failed"

**Symptoms**:
```
Error: Authentication failed. Have you logged in?
firebase login required
```

**Solution**:
```bash
# Method 1: Use service account (recommended for CI)
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
firebase deploy

# Method 2: Use stored token
firebase login:ci  # Generates a token
export FIREBASE_TOKEN="token_from_above"
firebase deploy

# Method 3: Check existing auth
firebase auth:list
firebase auth:logout
firebase login
```

---

### Issue: "Firestore rules deployment failed"

**Symptoms**:
```
Error: Could not update rules
firestore.rules validation error
```

**Solution**:
```bash
# Validate rules locally first
firebase emulators:start --only firestore

# In another terminal, test with emulator
firebase emulators:exec "npm run test"

# Check syntax
cat firestore.rules | head -20

# Deploy specific ruleset
firebase deploy --only firestore:rules
```

---

## Docker Issues

### Issue: "Docker daemon not running"

**Symptoms**:
```
Cannot connect to Docker daemon
```

**Solution**:
```bash
# Start Docker Desktop
open /Applications/Docker.app

# Or start daemon
sudo systemctl start docker

# Verify
docker ps

# If still issues, restart completely
docker system restart
```

---

### Issue: "Docker image build fails"

**Symptoms**:
```
docker build failed: Dockerfile parse error
```

**Solution**:
```bash
# Validate Dockerfile syntax
docker build --dry-run -f Dockerfile .

# Check file permissions
ls -la Dockerfile

# Rebuild with verbose output
docker build -f Dockerfile --progress=plain . 2>&1 | head -50

# Common issues:
# 1. Line endings (use LF, not CRLF)
# 2. Incorrect base image
# 3. Missing files referenced in Dockerfile
```

---

## Secret Management

### Issue: "Secret not available in workflow"

**Symptoms**:
```
Error: Secret not found: MY_SECRET
```

**Solution**:
```bash
# 1. Verify secret exists
gh secret list --org nelsongrey | grep MY_SECRET

# 2. If missing, create it
gh secret set MY_SECRET --org nelsongrey -b "secret_value"

# 3. Verify it's accessible in workflow
echo "Secret is ${{ secrets.MY_SECRET }}"

# 4. Check permissions
# Organization secrets are available to all repos in org
# Repository secrets are only available to that repo
```

---

### Issue: "Secret appears empty"

**Symptoms**:
```
Secret is empty or null
```

**Root Causes**:
1. Secret not passed to job
2. Secret passed to wrong context
3. Secret encoding issue

**Solutions**:
```yaml
# Workflow must inherit secrets
jobs:
  build:
    runs-on: ubuntu-latest
    secrets: inherit  # ← REQUIRED for org secrets

# Or explicitly pass
    secrets:
      MY_SECRET: ${{ secrets.MY_SECRET }}
```

---

### Issue: "Base64 encoded secret not decoded"

**Symptoms**:
```
Secret value looks like: SGVsbG8gV29ybGQ=
Expected: Hello World
```

**Solution**:
```bash
# When storing base64 encoded secrets
echo "SGVsbG8gV29ybGQ=" | base64 -d

# In workflow, decode before use
echo "${{ secrets.MY_BASE64_SECRET }}" | base64 -d > /tmp/decoded

# Or do it in code
decoded=$(echo "${{ secrets.MY_BASE64_SECRET }}" | base64 -d)
```

---

## GitHub Actions

### Issue: "Workflow doesn't trigger on push"

**Symptoms**:
- Push to develop branch
- No workflow runs
- No errors shown

**Root Causes**:
1. Workflow paths don't match
2. Workflow event filter doesn't match
3. Workflow file has syntax error

**Solutions**:
```bash
# 1. Check workflow file location
ls -la .github/workflows/main.yml

# 2. Verify syntax
yq eval '.on' .github/workflows/main.yml

# Expected output:
# push:
#   branches:
#   - develop
#   paths:
#   - packages/**

# 3. Check file paths match
git diff HEAD~1 HEAD --name-only | grep packages/
# If no output, path filter prevented trigger

# 4. Verify workflow is enabled
gh workflow list --repo mnelson3/modulo-squares

# 5. If still not working, manually trigger
gh workflow run main.yml --repo mnelson3/modulo-squares
```

---

### Issue: "Expression syntax error"

**Symptoms**:
```
Error: Unrecognized named-value: 'needs'
```

**Solution**:
```yaml
# WRONG: Missing ${{ }}
run: echo $needs.setup.outputs.result

# RIGHT: With expression syntax
run: echo ${{ needs.setup.outputs.result }}

# WRONG: Using dot without needs context
uses: ./actions/my-action@main
with:
  param: matrix.value

# RIGHT: With proper syntax
with:
  param: ${{ matrix.value }}
```

---

### Issue: "Reusable workflow not found"

**Symptoms**:
```
Error: Reusable workflow not found
```

**Solution**:
```yaml
# Correct format
jobs:
  build:
    uses: mnelson3/nelson-grey/.github/workflows/reusable/ios-build.yml@main
    with:
      project: modulo-squares

# Common mistakes:
# ✗ uses: .github/workflows/reusable/ios-build.yml (missing repo reference)
# ✗ uses: mnelson3/nelson-grey/.github/workflows/ios-build.yml (wrong file, not reusable)
# ✗ uses: mnelson3/nelson-grey/ios-build.yml (wrong path)

# Verify the reusable workflow exists:
# https://github.com/mnelson3/nelson-grey/blob/main/.github/workflows/reusable/ios-build.yml
```

---

## Performance

### Issue: "Workflows are slow"

**Symptoms**:
- Each build takes 30+ minutes
- Resource usage unclear

**Optimization**:
```yaml
# 1. Cache dependencies
- name: Cache Flutter dependencies
  uses: actions/cache@v4
  with:
    path: ~/.pub-cache
    key: flutter-${{ hashFiles('**/pubspec.lock') }}

# 2. Parallelize jobs
build-ios: ...
build-android: ...
build-web: ...
# These run in parallel, not sequentially

# 3. Minimize dependencies
# Only install what's needed for each job

# 4. Use matrix strategy
strategy:
  matrix:
    flutter-version: ['stable']
    os: ['ubuntu-latest', 'macos-latest']
```

---

### Issue: "Artifact upload is slow"

**Symptoms**:
- Upload IPA/APK takes 5+ minutes

**Solution**:
```yaml
# Compress before upload
- name: Compress artifact
  run: gzip -9 build/app/outputs/apk/*.apk

# Upload compressed
- uses: actions/upload-artifact@v4
  with:
    name: android-build
    path: build/app/outputs/**/*.apk.gz

# Reduce artifact retention
- uses: actions/upload-artifact@v4
  with:
    name: build
    path: build/
    retention-days: 7  # Default is 90
```

---

## Getting Help

### Diagnostic Command

```bash
# Collect comprehensive diagnostic information
./nelson-grey/scripts/diagnose.sh

# Output includes:
# - Fastlane version
# - Xcode version
# - Runner status
# - Keychain info
# - Recent workflow logs
```

### Community Resources

- [Fastlane Documentation](https://docs.fastlane.tools/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)

### Filing Issues

When reporting an issue, include:
1. Output of `diagnose.sh`
2. Relevant workflow YAML
3. Full error message (first 500 chars of relevant part)
4. Steps to reproduce
5. What you've already tried

---

## Checklist: Before Asking for Help

- [ ] Ran `validate-all-projects.sh` - passes
- [ ] Ran `health-monitor.sh check` - runner online
- [ ] Searched this guide for the error
- [ ] Tried the suggested solution
- [ ] Restarted the runner service
- [ ] Checked GitHub Actions workflow logs (not just summary)
- [ ] Tested locally with `act`
- [ ] Verified secrets are set
- [ ] Confirmed file changes trigger workflow
