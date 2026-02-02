# iOS TestFlight Build & Deployment Test Plan

**Date:** December 29, 2025  
**Project:** ZERO-TOUCH iOS APP DISTRIBUTION  
**Scope:** End-to-end iOS build, TestFlight deployment, and App Store Connect integration  
**Status:** TESTING PLAN (Ready to Execute)

---

## Executive Summary

This document outlines a comprehensive testing plan for the iOS build and TestFlight deployment workflow. The workflow integrates:
- Flutter iOS build process
- Fastlane automation
- Code signing with match (Git repository)
- App Store Connect API authentication
- TestFlight beta distribution
- App Store submission

**Objective:** Verify that the complete zero-touch iOS distribution pipeline works end-to-end from code commit to TestFlight availability.

---

## Test Environment Requirements

### Prerequisites
- **macOS Runner:** Self-hosted macOS runner with:
  - Xcode 15.x or later (`xcodebuild -version`)
  - Flutter 3.38.4 or later (`flutter --version`)
  - Ruby 3.2.x (`ruby --version`)
  - Fastlane 2.229.0 or later (`fastlane --version`)
  - Git configured with SSH access to code signing repo

- **GitHub Secrets Configured:**
  - `FASTLANE_APPLE_ID`: Apple ID email
  - `FASTLANE_TEAM_ID`: Apple Developer Team ID
  - `FASTLANE_ITC_TEAM_ID`: iTunes Connect Team ID
   - `APP_STORE_CONNECT_KEY_ID`: App Store Connect API Key ID
   - `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect Issuer ID
   - `APP_STORE_CONNECT_KEY`: App Store Connect private key (base64-encoded)
  - `MATCH_GIT_URL`: GitHub URL to code signing certificates repo
  - `MATCH_PASSWORD`: Encryption password for match certificates
  - `BETA_FEEDBACK_EMAIL`: Email for TestFlight feedback
  - `FIREBASE_SERVICE_ACCOUNT_KEY_*`: Firebase credentials (dev/staging/prod)

- **App Store Connect Setup:**
  - TestFlight beta group configured (e.g., "Internal Testers")
  - App version created and ready for builds
  - Build numbers sequential and unique

- **Code Signing Repo (nelson-grey):**
  - Valid signing certificates stored in:
    - `certificates/distribution/` (App Store distribution certs)
    - `certificates/development/` (Development certs)
    - `provisioning_profiles/` (Provisioning profiles)
  - Match encryption password set and accessible

---

## Test Cases

### Phase 1: Prerequisite Validation

#### TC1.1: macOS Runner Availability
```
Objective: Verify self-hosted macOS runner is operational
Steps:
1. SSH into macOS runner host
2. Execute: sw_vers -productVersion (verify macOS version)
3. Execute: xcodebuild -version (verify Xcode)
4. Execute: flutter --version (verify Flutter)
5. Execute: ruby --version (verify Ruby)
6. Execute: fastlane --version (verify Fastlane)

Expected Results:
✅ All tools installed and in PATH
✅ Versions match or exceed minimum requirements
✅ No permission errors
```

#### TC1.2: GitHub Secrets Validation
```
Objective: Verify all required GitHub secrets are configured
Steps:
1. Access repository settings → Secrets and variables → Actions
2. Verify each secret exists:
   - FASTLANE_APPLE_ID
   - FASTLANE_TEAM_ID
   - FASTLANE_ITC_TEAM_ID
   - APP_STORE_CONNECT_KEY_ID
   - APP_STORE_CONNECT_ISSUER_ID
   - APP_STORE_CONNECT_KEY
   - MATCH_GIT_URL
   - MATCH_PASSWORD
   - BETA_FEEDBACK_EMAIL

Expected Results:
✅ All 9 secrets present
✅ No empty values
✅ APP_STORE_CONNECT_KEY properly base64-encoded
```

#### TC1.3: Code Signing Repository Access
```
Objective: Verify access to Nelson Grey code signing repo
Steps:
1. SSH into runner
2. Execute: git ls-remote <MATCH_GIT_URL> (verify access)
3. Execute: git clone <MATCH_GIT_URL> /tmp/test-match (clone test)
4. Verify certificate structure exists:
   - certificates/distribution/
   - certificates/development/
   - provisioning_profiles/

Expected Results:
✅ SSH key access works (no password prompt)
✅ Repository clones successfully
✅ Certificate directories present and readable
✅ Match password decrypts certificates
```

#### TC1.4: App Store Connect API Authentication
```
Objective: Verify App Store Connect API key works
Steps:
1. SSH into runner
2. Extract APP_STORE_CONNECT_KEY from secrets
3. Create JWT token using API key
4. Execute: curl -H "Authorization: Bearer <JWT>" https://api.appstoreconnect.apple.com/v1/apps
5. Verify HTTP 200 response

Expected Results:
✅ JWT token generated successfully
✅ HTTP 200 response from App Store Connect API
✅ App list returned in response
```

---

### Phase 2: Flutter Build Preparation

#### TC2.1: iOS Platform Files Generation
```
Objective: Verify iOS platform files are correctly generated
Steps:
1. Navigate to: packages/mobile
2. Execute: flutter create --platforms=ios .
3. Verify iOS project structure:
   - ios/Runner.xcodeproj exists
   - ios/Podfile exists
   - ios/Runner/ directory exists

Expected Results:
✅ No errors during flutter create
✅ iOS platform directory properly initialized
✅ Xcode project loads without errors
```

#### TC2.2: Dependency Resolution
```
Objective: Verify Flutter dependencies and pods install correctly
Steps:
1. Execute: flutter pub get
2. Execute: cd ios && pod install --repo-update && cd ..
3. Verify no missing dependencies
4. Check Xcode project health

Expected Results:
✅ All pub dependencies resolved
✅ All pods installed
✅ No conflict warnings
✅ ios/Pods/Manifest.lock created
```

#### TC2.3: Build Settings Verification
```
Objective: Verify build settings are correctly configured
Steps:
1. Execute: xcodebuild -showBuildSettings -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release
2. Verify settings include:
   - CODE_SIGN_IDENTITY (correct signing identity)
   - PROVISIONING_PROFILE_SPECIFIER (correct profile)
   - BUNDLE_ID (com.nelsongrey.modulosquares.app.ios)
   - PRODUCT_BUNDLE_IDENTIFIER (matches BUNDLE_ID)

Expected Results:
✅ All build settings present and valid
✅ No warnings about provisioning
✅ Signing identity matches runner's code signing setup
```

---

### Phase 3: Fastlane Configuration & Secrets

#### TC3.1: Fastlane Environment Setup
```
Objective: Verify Fastlane environment variables are correctly set
Steps:
1. SSH into runner
2. Export required environment variables from GitHub secrets
3. Execute in packages/mobile/ios/:
   fastlane env
4. Verify output includes:
   - FASTLANE_APPLE_ID
   - FASTLANE_TEAM_ID
   - APP_STORE_CONNECT_KEY_ID
   - MATCH_GIT_URL (token included)
   - MATCH_PASSWORD

Expected Results:
✅ All environment variables exported
✅ Sensitive values masked in output
✅ No missing or empty variables
```

#### TC3.2: Match Certificate Sync
```
Objective: Verify match can sync code signing certificates
Steps:
1. Execute: cd packages/mobile/ios
2. Execute: fastlane match appstore --readonly (first run - should fetch)
3. Verify certificates synced:
   - Distribution certificate installed in keychain
   - Provisioning profiles in ~/Library/MobileDevice/Provisioning\ Profiles/

Expected Results:
✅ Match successfully syncs certificates
✅ Certificates load in keychain without errors
✅ Provisioning profiles accessible
✅ No permission errors from GitHub
```

#### TC3.3: Ephemeral Keychain Setup
```
Objective: Verify ephemeral keychain helper works correctly
Steps:
1. Execute: cd packages/mobile/ios
2. Run ephemeral keychain script: 
   ../../scripts/ephemeral_keychain_fastlane_fixed.sh "echo 'test'"
3. Verify:
   - Temporary keychain created
   - Script executed successfully
   - Temporary keychain cleaned up

Expected Results:
✅ Ephemeral keychain created
✅ Command executed in secure environment
✅ Keychain properly destroyed on exit
✅ No leftover keychains remain
```

---

### Phase 4: iOS App Build

#### TC4.1: Development Build
```
Objective: Verify development build completes successfully
Steps:
1. Execute: cd packages/mobile/ios
2. Execute: fastlane build_development
3. Monitor build output for:
   - Flutter build (packaging)
   - Xcode build (compilation)
   - Code signing
   - IPA generation

Expected Results:
✅ No build errors
✅ IPA file generated: build/ios/iphoneos/Runner.ipa
✅ Build artifacts in builds/ directory
✅ Completion timestamp logged
```

#### TC4.2: Build Artifact Validation
```
Objective: Verify generated IPA is valid
Steps:
1. After TC4.1 completes, examine artifacts:
2. Execute: ls -lh build/ios/iphoneos/Runner.ipa
3. Execute: unzip -t build/ios/iphoneos/Runner.ipa | head -20 (verify archive integrity)
4. Execute: file build/ios/iphoneos/Runner.ipa (verify file type)
5. Verify bundle structure:
   - Payload/Runner.app exists
   - Payload/Runner.app/Info.plist valid
   - Code signing certificate valid

Expected Results:
✅ IPA file present and >10MB
✅ Archive integrity verified (no errors)
✅ File type: Zip archive data
✅ Provisioning profile inside IPA
```

#### TC4.3: Code Signing Verification
```
Objective: Verify app is correctly code-signed
Steps:
1. After TC4.1 completes
2. Execute: unzip -p build/ios/iphoneos/Runner.ipa Payload/Runner.app/_CodeSignature/CodeResources | head -50
3. Execute: codesign -dvvv build/ios/iphoneos/Runner.ipa
4. Verify in output:
   - TeamIdentifier: 8L2QXZV8E (or correct team ID)
   - Executable: Runner

Expected Results:
✅ Codesign command succeeds
✅ Code signature is valid
✅ Team ID matches Apple Developer team
✅ All bundled resources signed correctly
```

---

### Phase 5: TestFlight Build Upload

#### TC5.1: TestFlight Build Upload
```
Objective: Verify TestFlight accepts and processes build
Steps:
1. Execute: cd packages/mobile/ios
2. Execute: fastlane beta (or manual upload via Transporter)
3. Monitor for:
   - Build uploaded successfully
   - Processing status (usually 10-30 minutes)
   - Compliance documents (if required)

Expected Results:
✅ Build uploaded without errors
✅ Build number incremented in App Store Connect
✅ Processing status shows in TestFlight
✅ No signature/provisioning errors reported
```

#### TC5.2: TestFlight Build Processing Verification
```
Objective: Verify build processes successfully in TestFlight
Steps:
1. Navigate to App Store Connect web UI
2. Select app → TestFlight tab → iOS Builds
3. Find uploaded build (highest build number)
4. Check status:
   - "Processing" → "Ready to Test" (success)
   - "Rejection" (failure - check logs)
5. If processing, wait 30 minutes and recheck

Expected Results:
✅ Build reaches "Ready to Test" status
✅ No rejection reasons listed
✅ Build ready for tester assignment
✅ Changelog/release notes visible
```

#### TC5.3: TestFlight Beta Tester Assignment
```
Objective: Verify beta testers can access build
Steps:
1. In App Store Connect: TestFlight tab → Internal Testers
2. Verify "Internal Testers" group exists
3. Verify testers are assigned to build
4. Send beta invite to test account
5. On iOS device: Accept TestFlight invite
6. Verify build appears in TestFlight app

Expected Results:
✅ Build appears in TestFlight app
✅ Testers can download and install
✅ App launches without crashes
✅ Firebase connection works
✅ Anonymous authentication succeeds
```

---

### Phase 6: GitHub Actions Workflow Execution

#### TC6.1: Workflow Trigger - Manual Dispatch
```
Objective: Verify iOS CI/CD workflow can be triggered manually
Steps:
1. Navigate to: GitHub Actions → iOS CI/CD & Release Pipeline
2. Click "Run workflow" button
3. Select workflow inputs:
   - release_type: testflight
   - release_notes: "Testing iOS build workflow [Dec 29]"
   - beta_group_name: Internal Testers
4. Click "Run workflow"
5. Monitor execution

Expected Results:
✅ Workflow starts immediately
✅ Runner assignment: self-hosted, macOS, ios
✅ All steps execute in order
✅ No step timeouts or failures
```

#### TC6.2: Workflow Step-by-Step Verification
```
Objective: Verify each workflow step completes successfully
Expected completion per step:

1. iOS Build Environment Check .......... ✅ <30s
   - Xcode version printed
   - macOS version confirmed
   - Runner cost savings noted

2. Fix Git Config for HTTPS ............ ✅ <10s
   - Git configuration updated
   - SSH redirects removed

3. Sync NTP Time ....................... ✅ <15s
   - System time synchronized
   - Ready for time-sensitive operations

4. Setup Flutter ....................... ✅ 2-5m
   - Flutter cache checked
   - Dependencies downloaded
   - flutter doctor shows 1 issue or 0 issues

5. Install GMP Library ................. ✅ <30s
   - GMP installed (Ruby dependency)

6. Setup Ruby .......................... ✅ 1-2m
   - Ruby 3.2 available
   - Bundler installed
   - ruby --version confirmed

7. Install Fastlane .................... ✅ 1-2m
   - Fastlane 2.229.0 installed
   - fastlane --version confirmed

8. Setup App Store Connect Auth ........ ✅ <15s
   - ASC private key file created
   - File exists at ~/.private_keys/

9. Test App Store Connect JWT .......... ✅ <30s
   - JWT token generated
   - API connectivity verified
   - HTTP 200 response

10. Generate iOS Platform Files ........ ✅ <30s
    - flutter create --platforms=ios
    - ios/Runner.xcodeproj exists

11. Setup Service Account Key .......... ✅ <10s
    - Service account key configured
    - Firebase authentication ready

12. Build and Distribute iOS App ....... ✅ 15-30m
    - Fastlane build_development or beta
    - IPA generated
    - All code signing steps succeed

13. Clean Up ........................... ✅ <10s
    - Private keys deleted
    - Service account files removed
    - Secure cleanup completed
```

#### TC6.3: Build Logs Analysis
```
Objective: Verify build logs contain expected information
Steps:
1. After workflow completes, review logs:
   - View each step's output
   - Search for errors/warnings
2. Expected patterns in logs:
   - No "codesign" errors
   - No "Match" sync failures
   - No "provisioning profile" errors
   - Build succeeded indicator
   - IPA file size output

Expected Results:
✅ All critical steps show success indicators
✅ No error logs for code signing
✅ No timeout messages
✅ Build duration logged: ~20-30 minutes
```

---

### Phase 7: iOS Workflow Build Type Options

#### TC7.1: Build Type - build_only
```
Objective: Test build_only workflow (compile without upload)
Steps:
1. Trigger workflow with: release_type: build_only
2. Monitor workflow execution
3. Verify:
   - IPA generated
   - No TestFlight upload attempted
   - Workflow completes successfully

Expected Results:
✅ Build only: IPA created, no upload
✅ Faster workflow (skips upload step)
✅ Good for PR validation builds
```

#### TC7.2: Build Type - testflight
```
Objective: Test testflight workflow (build + upload to TestFlight)
Steps:
1. Trigger workflow with: release_type: testflight
2. Monitor workflow execution
3. Verify:
   - IPA generated
   - Uploaded to TestFlight
   - Build appears in App Store Connect
   - Reaches "Ready to Test" status

Expected Results:
✅ Build uploaded to TestFlight
✅ Processing starts immediately
✅ Build number incremented
✅ Testers notified
```

#### TC7.3: Build Type - app_store
```
Objective: Test app_store workflow (full App Store submission)
Steps:
1. Trigger workflow with: release_type: app_store
2. Include release_notes
3. Monitor workflow execution
4. Verify:
   - IPA generated
   - Uploaded to App Store
   - Metadata updated (version, release notes)
   - Build submitted for review

Expected Results:
✅ Build submitted for App Store review
✅ Review status shows in App Store Connect
✅ Expected review time displayed
✅ Can optionally expedite review
```

#### TC7.4: Build Type - full_pipeline
```
Objective: Test full_pipeline workflow (build → TestFlight → App Store)
Steps:
1. Trigger workflow with: release_type: full_pipeline
2. Include release_notes and beta_group_name
3. Monitor workflow execution
4. Verify all stages:
   - Build succeeds
   - TestFlight upload succeeds
   - App Store submission succeeds
   - All approvals/compliance complete

Expected Results:
✅ Multi-stage pipeline completes
✅ IPA used for both TestFlight and App Store
✅ Build number matches across both platforms
✅ Release notes applied consistently
```

---

### Phase 8: Error Handling & Recovery

#### TC8.1: Code Signing Failure Handling
```
Objective: Verify graceful error handling for code signing issues
Trigger Condition: Simulate invalid provisioning profile
Steps:
1. Remove provisioning profile from match repo
2. Trigger build workflow
3. Verify:
   - Error message is clear
   - Workflow fails at appropriate step
   - Error logs contain actionable information

Expected Results:
✅ Clear error message
✅ Workflow stops at signing step
✅ Instructions for manual resolution provided
```

#### TC8.2: App Store Connect API Failure
```
Objective: Verify handling of App Store Connect API issues
Trigger Condition: Use expired/invalid App Store Connect API key
Steps:
1. Trigger build with invalid APP_STORE_CONNECT_KEY_ID
2. Monitor workflow
3. Verify:
   - API authentication fails with clear message
   - Workflow stops before attempting upload
   - Error suggests credential renewal

Expected Results:
✅ Authentication failure detected early
✅ Workflow fails before wasting time on build
✅ Error message suggests fix
```

#### TC8.3: Keychain Cleanup on Failure
```
Objective: Verify ephemeral keychain cleaned up even if build fails
Steps:
1. Trigger build that will fail (e.g., invalid dependencies)
2. Monitor keychain during execution
3. After workflow completion:
   Execute: security list-keychains -d user | grep fastlane_tmp
4. Verify no leftover keychains

Expected Results:
✅ Ephemeral keychain created during build
✅ Keychain removed even if build fails
✅ No accumulation of temporary keychains
```

---

### Phase 9: Performance & Optimization

#### TC9.1: Build Cache Efficiency
```
Objective: Measure build performance with caching
Steps:
1. First build: Trigger build workflow, measure time
2. Second build: Trigger again 30 minutes later, measure time
3. Compare timings
4. Expected improvements:
   - Flutter cache hit (no dependency download)
   - Pod cache hit (CocoaPods faster)
   - Xcode incremental build (faster compilation)

Expected Results:
✅ Second build faster than first
✅ Time savings: 20-30% (without full clean)
✅ Cache invalidation works correctly
```

#### TC9.2: iOS Runner Cost Savings
```
Objective: Verify cost savings from self-hosted runner
Comparison: GitHub-hosted macOS vs self-hosted
Steps:
1. Calculate per-build cost:
   - GitHub-hosted: $0.10/minute × 25 minutes = $2.50 per build
   - Self-hosted: Amortized infrastructure cost (~$0.10/build)
2. Estimate monthly savings:
   - 20 builds/month × $2.40 savings = $48/month

Expected Results:
✅ Self-hosted runner proven more cost-efficient
✅ Amortized cost per build < $0.50
✅ Significant savings over GitHub-hosted option
```

---

### Phase 10: Integration with Runner Infrastructure

#### TC10.1: Health Check - iOS Runner
```
Objective: Verify health check script detects iOS runner status
Steps:
1. SSH into macOS runner
2. Execute: ./scripts/health-check.sh
3. Verify output includes:
   - LaunchDaemon status: ✅ Running
   - Runner process: ✅ Running  
   - GitHub API: ✅ Reachable

Expected Results:
✅ 3-point health check passes
✅ Runner healthy and ready for builds
✅ No warnings or issues
```

#### TC10.2: Auto-Recovery - Simulated Failure
```
Objective: Verify auto-recovery restarts iOS runner after crash
Steps:
1. SSH into macOS runner
2. Kill runner process: pkill -9 -f "actions/run.js"
3. Monitor for auto-recovery (5 minute interval)
4. Verify:
   - Auto-recovery script detects failure
   - Runner process restarted
   - Service back online within 10 minutes

Expected Results:
✅ Auto-recovery detects failure
✅ Runner automatically restarted
✅ No manual intervention required
✅ Ready for next build immediately
```

#### TC10.3: Monitoring - iOS Runner Logs
```
Objective: Verify monitoring captures iOS build execution
Steps:
1. Execute build workflow
2. Check runner monitoring logs:
   tail -f scripts/monitor.log
3. Verify log entries include:
   - Workflow start timestamp
   - Step execution timings
   - Success/failure indicators
   - Resource usage (CPU, memory)

Expected Results:
✅ Build execution logged with timestamps
✅ Workflow duration captured
✅ Success/failure clearly indicated
✅ Logs useful for performance analysis
```

---

## Test Execution Timeline

| Phase | Test Cases | Est. Duration | Prerequisites |
|-------|-----------|---|---|
| 1 | TC1.1-1.4 | 30 min | Secrets configured, runner ready |
| 2 | TC2.1-2.3 | 20 min | iOS platform available |
| 3 | TC3.1-3.3 | 15 min | Match repo accessible |
| 4 | TC4.1-4.3 | 25 min | Previous phases passed |
| 5 | TC5.1-5.3 | 60 min | Build completed, 30min processing |
| 6 | TC6.1-6.3 | 30 min | Workflow triggered |
| 7 | TC7.1-7.4 | 60 min | Build types sequential |
| 8 | TC8.1-8.3 | 45 min | Failure scenarios prepared |
| 9 | TC9.1-9.2 | 30 min | Multiple runs, timing captured |
| 10 | TC10.1-10.3 | 30 min | Runner monitoring enabled |
| **TOTAL** | **40 test cases** | **~5-6 hours** | **All prerequisites ready** |

---

## Success Criteria

### Overall Status: ✅ PASS
- [ ] All 40 test cases passed
- [ ] Zero critical failures
- [ ] Build time < 30 minutes (excluding TestFlight processing)
- [ ] No manual intervention required during build
- [ ] All workflows complete without errors

### Build Quality: ✅ PASS
- [ ] IPA file valid and >10MB
- [ ] Code signing verified
- [ ] All dependencies resolved
- [ ] Firebase integration working
- [ ] App launches without crashes

### Distribution: ✅ PASS  
- [ ] TestFlight build reaches "Ready to Test" status
- [ ] Internal testers receive notifications
- [ ] Build downloadable in TestFlight app
- [ ] App Store submission successful
- [ ] Release notes preserved through pipeline

### Automation: ✅ PASS
- [ ] GitHub workflow fully automated
- [ ] No manual approval steps required
- [ ] All environment variables resolved
- [ ] Secrets managed securely
- [ ] Logging captures all steps

### Infrastructure: ✅ PASS
- [ ] Self-hosted runner stable
- [ ] Health checks pass
- [ ] Auto-recovery functional
- [ ] Cost savings verified
- [ ] Monitoring captures execution

---

## Known Issues & Mitigations

| Issue | Cause | Mitigation |
|-------|-------|-----------|
| Xcode version compatibility | Different Xcode versions behave differently | Pin Xcode version in workflow |
| Provisioning profile expiry | Certificates/profiles expire annually | Set calendar reminders, automate renewal |
| Match sync failures | Network issues or permission errors | Retry logic in match, clear error messages |
| TestFlight processing delay | Apple processing queues full | No action needed, expected 10-30 min wait |
| Keychain warnings | Multiple keychains on runner | Ephemeral keychain cleanup prevents accumulation |

---

## Rollback Procedures

### If Build Fails in GitHub Actions
1. Check error logs for root cause
2. If code signing issue:
   - Verify MATCH_PASSWORD correct
   - Verify APP_STORE_CONNECT_KEY_ID valid
   - Re-run match command manually
3. If dependency issue:
   - Check pubspec.lock/Podfile.lock
   - Run `flutter clean && flutter pub get`
4. Re-trigger workflow after fix

### If TestFlight Upload Fails
1. Verify build number is unique (>previous build number)
2. Check App Store Connect for duplicate version
3. Try manual upload via Transporter
4. Check Fastlane logs for specific error

### If App Store Submission Fails
1. Verify metadata (version, release notes) valid
2. Check build passes internal review criteria
3. Ensure compliance documents uploaded
4. Manual submission via App Store Connect web

---

## Documentation References

- [iOS CI/CD Workflow](../.github/workflows/ios-cicd-release.yml)
- [Fastlane Configuration](../../packages/mobile/ios/fastlane/Fastfile)
- [Runner Setup Guide](./docs/DEPLOYMENT_GUIDE.md)
- [Completion Summary](./docs/ZERO_TOUCH_COMPLETION_SUMMARY.md)

---

## Next Steps

1. **Immediate:** Execute Phase 1 tests (Prerequisite Validation) ➜ 30 minutes
2. **Week 1:** Execute Phases 2-6 (build through workflow execution) ➜ 2-3 hours
3. **Week 2:** Execute Phases 7-10 (optimization and integration) ➜ 2-3 hours
4. **Ongoing:** Document results and optimize based on findings

---

**Test Plan Created:** December 29, 2025  
**Status:** Ready for Execution  
**Owner:** GitHub Copilot  
**Approval:** Pending Team Review
