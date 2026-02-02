# iOS TestFlight Build Testing — Execution Checklist

**Project:** ZERO-TOUCH iOS APP DISTRIBUTION  
**Test Date:** December 29, 2025  
**Tester Name:** ___________________  
**Runner Host:** ___________________  
**Status:** ⬜ NOT STARTED

---

## Pre-Test Verification (Do This First!)

### Environment Check
- [ ] Runner is online and accessible via SSH
- [ ] GitHub secrets verified in repository settings
- [ ] Code signing repository (nelson-grey) accessible
- [ ] Apple Developer account credentials valid
- [ ] TestFlight beta group configured in App Store Connect

### Required Files Present
- [ ] `.github/workflows/ios-cicd-release.yml` exists
- [ ] `packages/mobile/ios/fastlane/Fastfile` exists
- [ ] `scripts/ephemeral_keychain_fastlane_fixed.sh` executable
- [ ] `pubspec.yaml` and `pubspec.lock` in place
- [ ] Firebase configuration files (`google-services.json`, `GoogleService-Info.plist`)

### Tool Verification (Run on Runner)
```bash
sw_vers -productVersion           # macOS version
xcodebuild -version               # Xcode version
flutter --version                 # Flutter version
ruby --version                    # Ruby version
fastlane --version                # Fastlane version
git --version                     # Git version
```

**Versions Found:**
- macOS: ___________
- Xcode: ___________
- Flutter: ___________
- Ruby: ___________
- Fastlane: ___________

---

## Phase 1: Prerequisite Validation (30 min)

### TC1.1: macOS Runner Availability
```bash
# On runner, execute each command and note results
sw_vers -productVersion
xcodebuild -version
flutter --version
ruby --version
fastlane --version
```

**Results:**
- [ ] macOS version ≥ 12.x
- [ ] Xcode version ≥ 15.x
- [ ] Flutter version ≥ 3.38.4
- [ ] Ruby version = 3.2.x
- [ ] Fastlane version ≥ 2.229.0

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC1.2: GitHub Secrets Validation
Navigate to GitHub repo → Settings → Secrets and variables → Actions

**Check Each Secret:**
- [ ] FASTLANE_APPLE_ID (value: _______________)
- [ ] FASTLANE_TEAM_ID (value: _______________)
- [ ] FASTLANE_ITC_TEAM_ID (value: _______________)
- [ ] APP_STORE_CONNECT_KEY_ID (value: _______________)
- [ ] APP_STORE_CONNECT_ISSUER_ID (value: _______________)
- [ ] APP_STORE_CONNECT_KEY (exists: Y/N)
- [ ] MATCH_GIT_URL (value: _______________)
- [ ] MATCH_PASSWORD (exists: Y/N)
- [ ] BETA_FEEDBACK_EMAIL (value: _______________)

**Missing Secrets Found:**
- _________________________________________________

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC1.3: Code Signing Repository Access
```bash
# On runner
git ls-remote git@github.com:mnelson3/nelson-grey.git
git clone git@github.com:mnelson3/nelson-grey.git /tmp/test-match
ls -la /tmp/test-match/certificates/distribution/
ls -la /tmp/test-match/certificates/development/
ls -la /tmp/test-match/provisioning_profiles/
```

**Results:**
- [ ] Git SSH access works (no password prompt)
- [ ] Repository clones successfully
- [ ] certificates/distribution/ readable
- [ ] certificates/development/ readable
- [ ] provisioning_profiles/ readable

**Issues Found:**
- _________________________________________________

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC1.4: App Store Connect API Authentication
```bash
# On runner
cd /tmp
openssl ecparam -genkey -name prime256v1 -noout -out test.key
# (Create test JWT token)
curl -H "Authorization: Bearer <JWT>" https://api.appstoreconnect.apple.com/v1/apps
```

**Results:**
- [ ] JWT token generated successfully
- [ ] HTTP 200 response from App Store Connect API
- [ ] App list returned in response

**API Response Status:** ___________

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

## Phase 2: Flutter Build Preparation (20 min)

### TC2.1: iOS Platform Files Generation
```bash
cd packages/mobile
flutter create --platforms=ios .
```

**Results:**
- [ ] No errors during flutter create
- [ ] ios/Runner.xcodeproj exists
- [ ] ios/Podfile exists
- [ ] ios/Runner/ directory exists

**Files Generated:**
- ios/Runner.xcodeproj: ✅ Exists
- ios/Podfile: ✅ Exists
- ios/Runner/: ✅ Exists

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC2.2: Dependency Resolution
```bash
flutter pub get
cd ios && pod install --repo-update && cd ..
```

**Results:**
- [ ] All pub dependencies resolved
- [ ] All pods installed
- [ ] No conflict warnings
- [ ] ios/Pods/Manifest.lock created

**Issues Found:**
- _________________________________________________

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC2.3: Build Settings Verification
```bash
xcodebuild -showBuildSettings -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release | grep -E "CODE_SIGN|PROVISIONING|BUNDLE_ID|PRODUCT"
```

**Build Settings:**
- CODE_SIGN_IDENTITY: ___________
- PROVISIONING_PROFILE_SPECIFIER: ___________
- BUNDLE_ID: ___________
- PRODUCT_BUNDLE_IDENTIFIER: ___________

**Results:**
- [ ] All settings present and valid
- [ ] No warnings about provisioning
- [ ] Signing identity matches runner

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

## Phase 3: Fastlane Configuration (15 min)

### TC3.1: Fastlane Environment Setup
```bash
cd packages/mobile/ios
fastlane env
```

**Results:**
- [ ] FASTLANE_APPLE_ID set
- [ ] FASTLANE_TEAM_ID set
- [ ] APP_STORE_CONNECT_KEY_ID set
- [ ] MATCH_GIT_URL set
- [ ] MATCH_PASSWORD set

**Issues Found:**
- _________________________________________________

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC3.2: Match Certificate Sync
```bash
cd packages/mobile/ios
fastlane match appstore --readonly
```

**Results:**
- [ ] Match successfully syncs certificates
- [ ] Distribution certificate installed
- [ ] Provisioning profiles in ~/Library/MobileDevice/
- [ ] No permission errors from GitHub

**Certificates Synced:**
- Distribution Certificate: ✅
- Provisioning Profile: ✅

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC3.3: Ephemeral Keychain Setup
```bash
../../scripts/ephemeral_keychain_fastlane_fixed.sh "echo 'test'"
```

**Results:**
- [ ] Ephemeral keychain created
- [ ] Command executed successfully
- [ ] Temporary keychain cleaned up
- [ ] No leftover keychains

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

## Phase 4: iOS App Build (25 min)

### TC4.1: Development Build
```bash
cd packages/mobile/ios
fastlane build_development
```

**Build Output:**
- Build started at: ___________
- Build completed at: ___________
- Total duration: ___________
- IPA file size: ___________

**Results:**
- [ ] No build errors
- [ ] IPA file generated
- [ ] Build artifacts in builds/
- [ ] Completion timestamp logged

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC4.2: Build Artifact Validation
```bash
ls -lh build/ios/iphoneos/Runner.ipa
unzip -t build/ios/iphoneos/Runner.ipa | head -20
file build/ios/iphoneos/Runner.ipa
```

**Results:**
- [ ] IPA file present
- [ ] IPA file size > 10MB (actual: ___ MB)
- [ ] Archive integrity verified
- [ ] File type: Zip archive

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC4.3: Code Signing Verification
```bash
codesign -dvvv build/ios/iphoneos/Runner.ipa
```

**Results:**
- [ ] Codesign command succeeds
- [ ] Code signature is valid
- [ ] Team ID matches: 8L2QXZV8E
- [ ] All resources signed

**Team ID Found:** ___________

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

## Phase 5: TestFlight Build Upload (60 min)

### TC5.1: TestFlight Build Upload
```bash
cd packages/mobile/ios
fastlane beta
```

**Upload Results:**
- Upload started at: ___________
- Upload completed at: ___________
- Build number uploaded: ___________

**Results:**
- [ ] Build uploaded without errors
- [ ] Build number incremented
- [ ] Processing status shown

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

⏳ **WAIT 10-30 minutes for App Store Connect to process...**

---

### TC5.2: TestFlight Build Processing Verification
Navigate to App Store Connect → TestFlight → iOS Builds

**Status Check:**
- Build number in TestFlight: ___________
- Processing status: ___________
- Expected status: "Ready to Test" or "Processing"

**Results:**
- [ ] Build reaches "Ready to Test" status
- [ ] No rejection reasons listed
- [ ] Build ready for tester assignment

**Time to "Ready to Test":** ___________ minutes

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC5.3: TestFlight Beta Tester Assignment
In App Store Connect:
1. TestFlight tab → Internal Testers
2. Verify build assigned
3. Send beta invite to test account
4. Accept in TestFlight app on iOS device
5. Verify app appears and can be installed

**Results:**
- [ ] Build appears in TestFlight app
- [ ] Testers can download
- [ ] App launches without crashes
- [ ] Firebase connection works
- [ ] Anonymous auth succeeds

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

## Phase 6: GitHub Actions Workflow Execution (30 min)

### TC6.1: Workflow Trigger
Navigate to GitHub Actions → iOS CI/CD & Release Pipeline

**Workflow Details:**
- Branch: main (or develop for testing)
- Release Type: testflight
- Release Notes: Testing iOS workflow - [Date]
- Beta Group: Internal Testers

**Results:**
- [ ] Workflow starts immediately
- [ ] Runner assigned: self-hosted, macOS, ios
- [ ] Execution URL: ___________

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC6.2: Workflow Step Execution
Monitor GitHub Actions logs for each step:

| Step | Expected | Status | Duration |
|------|----------|--------|----------|
| Env Check | ✅ | ⬜ | ____ |
| Git Config | ✅ | ⬜ | ____ |
| NTP Sync | ✅ | ⬜ | ____ |
| Flutter Setup | ✅ | ⬜ | ____ |
| GMP Install | ✅ | ⬜ | ____ |
| Ruby Setup | ✅ | ⬜ | ____ |
| Fastlane Install | ✅ | ⬜ | ____ |
| ASC Auth Setup | ✅ | ⬜ | ____ |
| JWT Test | ✅ | ⬜ | ____ |
| Platform Files | ✅ | ⬜ | ____ |
| Service Account | ✅ | ⬜ | ____ |
| Build & Distribute | ✅ | ⬜ | ____ |
| Cleanup | ✅ | ⬜ | ____ |

**Results:**
- [ ] All steps complete
- [ ] Total workflow time: ___________
- [ ] No step timeouts

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC6.3: Workflow Logs Analysis
Review GitHub workflow logs for:

**Search Results:**
- [ ] No "codesign" errors found
- [ ] No "Match" failures found
- [ ] No "provisioning profile" errors found
- [ ] Build succeeded indicator found
- [ ] IPA file size output logged
- [ ] Total build time logged: ___________

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

## Phase 7: Build Type Options (60 min total)

### TC7.1: build_only
```
release_type: build_only
```

**Results:**
- [ ] IPA generated
- [ ] No TestFlight upload
- [ ] Workflow time: ___________

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC7.2: testflight
```
release_type: testflight
```

**Results:**
- [ ] IPA generated
- [ ] Uploaded to TestFlight
- [ ] Build in App Store Connect
- [ ] Workflow time: ___________

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC7.3: app_store (⚠️ CAUTION: Real App Store submission)
```
release_type: app_store
```

**Results:**
- [ ] IPA generated
- [ ] Uploaded to App Store
- [ ] Build submitted for review
- [ ] Workflow time: ___________

**⚠️ WARNING:** This submits to App Store. Only proceed if authorized.

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC7.4: full_pipeline (⚠️ CAUTION: Full release)
```
release_type: full_pipeline
```

**Results:**
- [ ] Build succeeds
- [ ] TestFlight upload succeeds
- [ ] App Store submission succeeds
- [ ] Workflow time: ___________

**⚠️ WARNING:** This is a complete release. Only proceed if authorized.

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

## Phase 8: Error Handling (45 min)

### TC8.1: Code Signing Failure
*Deliberately trigger signing error to test recovery*

**Setup:**
- Remove provisioning profile from match repo
- Trigger build

**Results:**
- [ ] Error message is clear
- [ ] Workflow fails at signing step
- [ ] Actionable instructions provided

**Error Message Found:**
- _________________________________________________

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC8.2: API Failure
*Use invalid App Store Connect API key*

**Setup:**
- Modify APP_STORE_CONNECT_KEY_ID to invalid value
- Trigger build

**Results:**
- [ ] Auth failure detected early
- [ ] Workflow stops before build
- [ ] Error suggests credential renewal

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC8.3: Keychain Cleanup
*Verify cleanup even after failure*

**Setup:**
- Trigger failing build
- After completion, check keychains

**Results:**
- [ ] Ephemeral keychain created
- [ ] Keychain removed on failure
- [ ] No leftover keychains:
  ```bash
  security list-keychains -d user | grep fastlane_tmp
  ```

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

## Phase 9: Performance (30 min)

### TC9.1: Build Cache Efficiency
**First Build:**
- Start time: ___________
- End time: ___________
- Duration: ___________

**Second Build (30 min later):**
- Start time: ___________
- End time: ___________
- Duration: ___________

**Cache Improvement:**
- [ ] Second build faster than first
- [ ] Time savings: ___________ seconds (___________ %)

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC9.2: Cost Analysis
**Per-Build Cost Comparison:**

GitHub-Hosted macOS:
- Minutes per build: ___________
- Cost: 0.10/min × ___ = $___________

Self-Hosted Runner:
- Amortized cost: $___________
- Savings per build: $___________

**Monthly Estimate (20 builds):**
- GitHub-Hosted cost: $___________
- Self-Hosted cost: $___________
- Monthly savings: $___________

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

## Phase 10: Runner Integration (30 min)

### TC10.1: Health Check
```bash
./scripts/health-check.sh
```

**Results:**
- [ ] LaunchDaemon status: ✅ Running
- [ ] Runner process: ✅ Running
- [ ] GitHub API: ✅ Reachable
- [ ] Overall health: ✅ Healthy

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC10.2: Auto-Recovery
```bash
# Kill runner process
pkill -9 -f "actions/run.js"

# Wait for recovery (5-10 min)
sleep 300

# Verify recovery
./scripts/health-check.sh
```

**Results:**
- [ ] Process killed successfully
- [ ] Auto-recovery detected failure
- [ ] Runner restarted automatically
- [ ] Back online within: ___________

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

### TC10.3: Monitoring Logs
```bash
tail -f scripts/monitor.log
```

**Results:**
- [ ] Build execution logged with timestamps
- [ ] Workflow duration captured
- [ ] Success/failure indicated
- [ ] Resource usage visible

**Sample Log Entry:**
```
[2025-12-29 15:30:45] Workflow started: ios-cicd-release
[2025-12-29 15:55:32] Build completed: SUCCESS
[2025-12-29 15:55:32] IPA size: 487.2 MB
```

**Status:** ⬜ Not Started | ⏳ In Progress | ✅ PASSED | ❌ FAILED

---

## Final Summary

### Overall Test Status

**Phase 1: Prerequisites** ⬜ 
**Phase 2: Flutter Prep** ⬜
**Phase 3: Fastlane Config** ⬜
**Phase 4: iOS Build** ⬜
**Phase 5: TestFlight Upload** ⬜
**Phase 6: GitHub Workflow** ⬜
**Phase 7: Build Types** ⬜
**Phase 8: Error Handling** ⬜
**Phase 9: Performance** ⬜
**Phase 10: Integration** ⬜

### Test Results

**Total Test Cases:** 40  
**Passed:** _____ / 40  
**Failed:** _____ / 40  
**Skipped:** _____ / 40  

**Pass Rate:** __________%

### Critical Issues Found

- Issue #1: _________________________________________________
- Issue #2: _________________________________________________
- Issue #3: _________________________________________________

### Recommendations

1. _________________________________________________
2. _________________________________________________
3. _________________________________________________

### Sign-Off

**Tester Name:** ___________________________  
**Date:** ___________________________  
**Status:** ⬜ INCOMPLETE | ⏳ IN PROGRESS | ✅ PASSED | ❌ FAILED

**Approved By:** ___________________________  
**Date:** ___________________________

---

**Testing Template Version:** 1.0  
**Created:** December 29, 2025
