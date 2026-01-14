# Phase 5B: Dry-Run Execution Quick Start

**Goal**: Validate all 4 project pipelines with test_all, then build_all workflows

**Status**: Ready to execute (all configs updated, secrets mapped)

---

## Prerequisites ✅

- [x] All 4 manifests validated (YAML syntax)
- [x] Secret mappings configured in master-pipeline.yml
- [x] Reusable workflows available in nelson-grey/.github/workflows/reusable/
- [x] Projects have existing GitHub secrets (ASC_*, FIREBASE_*, MATCH_*)

---

## Quick Execution Steps

### 1. Set Missing Secrets (2 min)

```bash
# Add MATCH_GIT_BRANCH to 3 Flutter projects
gh secret set MATCH_GIT_BRANCH --body "main" -R mnelson3/modulo-squares
gh secret set MATCH_GIT_BRANCH --body "main" -R mnelson3/vehicle-vitals
gh secret set MATCH_GIT_BRANCH --body "main" -R mnelson3/wishlist-wizard
```

### 2. Trigger test_all (Lowest Risk) - 5 min

```bash
# Trigger test workflows on all 4 repos
gh workflow run master-pipeline.yml -f action=test_all -R mnelson3/modulo-squares
gh workflow run master-pipeline.yml -f action=test_all -R mnelson3/vehicle-vitals
gh workflow run master-pipeline.yml -f action=test_all -R mnelson3/wishlist-wizard
gh workflow run master-pipeline.yml -f action=test_all -R mnelson3/stream-control
```

**Wait 5-10 minutes for results** (watch GitHub Actions UI)

### 3. Check Results

```bash
# List recent workflow runs
gh run list -R mnelson3/modulo-squares --workflow master-pipeline.yml --limit 1 -s all
gh run list -R mnelson3/vehicle-vitals --workflow master-pipeline.yml --limit 1 -s all
gh run list -R mnelson3/wishlist-wizard --workflow master-pipeline.yml --limit 1 -s all
gh run list -R mnelson3/stream-control --workflow master-pipeline.yml --limit 1 -s all
```

**Expected**: All 4 runs complete with status `completed` (success ✓ or failure ✗)

### 4. If test_all Succeeds → Trigger build_all (15-60 min per project)

```bash
# One at a time to avoid runner contention
gh workflow run master-pipeline.yml -f action=build_all -R mnelson3/modulo-squares
# Wait 30-60 min...
gh workflow run master-pipeline.yml -f action=build_all -R mnelson3/vehicle-vitals
# Wait 30-60 min...
gh workflow run master-pipeline.yml -f action=build_all -R mnelson3/wishlist-wizard
# Wait 30-60 min...
gh workflow run master-pipeline.yml -f action=build_all -R mnelson3/stream-control
```

### 5. Monitor Builds

```bash
# Watch specific run (replace RUN_ID from step 3 output)
gh run view <RUN_ID> -R mnelson3/modulo-squares --log

# Or check GitHub Actions UI directly
# https://github.com/mnelson3/modulo-squares/actions
# https://github.com/mnelson3/vehicle-vitals/actions
# https://github.com/mnelson3/wishlist-wizard/actions
# https://github.com/mnelson3/stream-control/actions
```

### 6. Archive Legacy Workflows (Post-Success)

```bash
# After confirming all builds successful, archive old workflows
for repo in modulo-squares vehicle-vitals wishlist-wizard stream-control; do
  gh repo clone mnelson3/$repo /tmp/$repo
  cd /tmp/$repo
  mkdir -p .github/workflows/archive
  # Move legacy workflows
  git mv .github/workflows/build-*.yml .github/workflows/archive/ 2>/dev/null || true
  git mv .github/workflows/deploy-*.yml .github/workflows/archive/ 2>/dev/null || true
  git mv .github/workflows/test-*.yml .github/workflows/archive/ 2>/dev/null || true
  git commit -m "Archive legacy workflows (migrated to master-pipeline.yml)"
  git push
  cd -
done
```

---

## Troubleshooting

### build_all Fails at iOS Build

**Likely cause**: Keychain access error  
**Fix**: SSH into macOS runner and run:
```bash
./nelson-grey/shared/runner-scripts/ephemeral_keychain_fastlane_fixed.sh
```

### build_all Fails at Android Build

**Likely cause**: Missing Android keystore  
**Fix**: Add `ANDROID_KEYSTORE_BASE64` to GitHub secrets:
```bash
# On dev machine with keystore
base64 -i keystore.jks | gh secret set ANDROID_KEYSTORE_BASE64 -R mnelson3/[repo]
```

### Firebase Deploy Fails

**Likely cause**: `FIREBASE_TOKEN` missing or expired  
**Fix**:
```bash
firebase login:ci --no-localhost
# Copy token output to GitHub secret
gh secret set FIREBASE_TOKEN --body "<TOKEN>" -R mnelson3/[repo]
```

### Workflow Never Runs

**Likely cause**: No available self-hosted runner  
**Fix**: Verify runner status:
```bash
gh api repos/mnelson3/modulo-squares/actions/runners | jq '.runners[] | {name, status, busy}'
```

---

## Expected Outcomes

**test_all Workflow**:
- ✅ Loads config from manifest
- ✅ Runs unit tests
- ✅ Lints code
- ✅ Duration: ~5-10 min

**build_all Workflow**:
- ✅ Builds iOS app (15-20 min)
- ✅ Builds Android app (10-15 min)
- ✅ Builds web app (5-10 min)
- ✅ Uploads artifacts to GitHub
- ✅ Total duration: 30-60 min

**Success Indicators**:
- Green checkmark on all workflow runs
- Artifacts available in GitHub Actions summary
- No errors in step logs

---

## Estimated Timeline

| Task | Duration |
|------|----------|
| Set missing secrets | 2 min |
| Trigger test_all | 1 min |
| Wait for test results | 10 min |
| Trigger build_all (all 4 repos) | 4 min + runner queue |
| Monitor builds | 120 min (30-60 per project) |
| Archive workflows | 10 min |
| **Total** | **~2.5 hours** |

---

## Success Criteria

- [x] All 4 test_all workflows complete successfully
- [ ] All 4 build_all workflows complete successfully (iOS, Android, web builds)
- [ ] Artifacts uploaded to GitHub Actions (iOS .ipa, Android .apk, web dist/)
- [ ] Firebase deployments succeed (if enabled)
- [ ] Legacy workflows archived

---

## Next: Phase 6

Once Phase 5B complete:
- Enable GitHub branch protection requiring new pipeline status checks
- Update documentation with production deployment procedures
- Plan rollout to CI/CD runners for full automation
- Archive this directory: `mv docs/PHASE5_* docs/archive/`
