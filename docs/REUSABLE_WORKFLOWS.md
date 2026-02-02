# Reusable Workflows Documentation

Complete reference for all reusable GitHub Actions workflows created for the CI/CD system.

## Overview

The reusable workflows implement the "Reusable Components" layer of the three-layer architecture. They encapsulate all build and deployment logic for each platform/service, eliminating duplication and ensuring consistency across all projects.

**Workflow Files Location**: `.github/workflows/reusable/`

## Quick Reference

| Workflow | Purpose | Platforms | When to Use |
|----------|---------|-----------|------------|
| `ios-build.yml` | iOS app building and distribution | iOS (Swift/Flutter) | All Flutter iOS projects |
| `android-build.yml` | Android app building and distribution | Android (Kotlin/Flutter) | All Flutter Android projects |
| `web-deploy.yml` | Web app building and Firebase Hosting deployment | Web (React/Next.js/Vue) | All web projects |
| `firebase-deploy.yml` | Firebase Functions, Firestore Rules, and Indexes | Backend (Node.js) | All backend projects |
| `chrome-extension-submit.yml` | Chrome extension building and Web Store submission | Browser Extension | All extension projects |
| `master-pipeline.yml` | Orchestration workflow that coordinates all builds | Meta | Main entry point for CI/CD |

---

## iOS Build & Distribution (`ios-build.yml`)

Handles building, signing, and distributing Flutter iOS apps to TestFlight and App Store.

### Inputs

```yaml
inputs:
  project_name:
    type: string
    description: Name of the project (e.g., 'vehicle-vitals')
    required: true
  mobile_dir:
    type: string
    default: "packages/mobile"
    description: Path to mobile directory
  release_type:
    type: string
    description: build_only | testflight | app_store | full_pipeline
    required: true
  release_notes:
    type: string
    description: Release notes for this build
  ruby_version:
    type: string
    default: "3.2"
    description: Ruby version for Fastlane
  bundler_version:
    type: string
    default: "2.4.22"
    description: Bundler version
  fastlane_version:
    type: string
    default: "2.230.0"
    description: Fastlane version (IMPORTANT: 2.230.0 is stable and supported)
```

### Required Secrets

```yaml
secrets:
  app_store_connect_key_id: string        # App Store Connect key ID
  app_store_connect_issuer_id: string     # App Store Connect issuer ID
  app_store_connect_key: string           # App Store Connect private key (P8)
  match_password: string                  # Password for match certificate repository
  match_git_url: string                   # Git URL for match certificates repo
  match_git_branch: string                # Git branch for match certificates
```

### What It Does

1. **Environment Setup**
   - Verifies macOS runner configuration
   - Configures Git for HTTPS checkout
   - Syncs NTP time (critical for code signing)

2. **Flutter & Dependencies**
   - Installs Flutter (stable channel)
   - Gets Flutter dependencies
   - Installs GMP (Ruby dependency)

3. **Ruby & Fastlane**
   - Sets up Ruby 3.2 with Bundler 2.4.22
   - Installs Fastlane 2.230.0 (specific version for stability)
   - Installs CocoaPods for dependency management

4. **Code Signing**
   - Downloads and imports Apple WWDR certificate
   - Sets up App Store Connect authentication
   - Configures match for certificate management
   - **KEY FIX**: Uses `$HOME/Library/Keychains` (not RUNNER_TEMP)

5. **Build & Distribution**
   - Builds for specified release_type:
     - `build_only`: Local build without signing
     - `testflight`: Build and upload to TestFlight
     - `app_store`: Build and release to App Store
     - `full_pipeline`: TestFlight then App Store

6. **Cleanup & Reporting**
   - Removes sensitive files
   - Generates detailed summary

### Usage in Project

```yaml
# .github/workflows/main.yml in project repository

uses: mnelson3/nelson-grey/.github/workflows/reusable/ios-build.yml@develop
with:
  project_name: "vehicle-vitals"
  release_type: ${{ inputs.release_type || 'build_only' }}
  release_notes: ${{ inputs.release_notes || '' }}
secrets:
  app_store_connect_key_id: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
  app_store_connect_issuer_id: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
  app_store_connect_key: ${{ secrets.APP_STORE_CONNECT_KEY }}
  match_password: ${{ secrets.MATCH_PASSWORD }}
  match_git_url: ${{ secrets.MATCH_GIT_URL }}
  match_git_branch: ${{ secrets.MATCH_GIT_BRANCH }}
```

### Environment Variables (Used by Fastlane)

Automatically set by workflow:
- `MATCH_PASSWORD`: Certificate repository password
- `MATCH_GIT_URL`: Certificate repository URL
- `MATCH_GIT_BRANCH`: Certificate repository branch
- `APP_STORE_CONNECT_KEY_ID`: ASC key ID
- `APP_STORE_CONNECT_ISSUER_ID`: ASC issuer ID
- `APP_STORE_CONNECT_KEY_FILE`: Path to ASC key P8 file

### Common Issues & Solutions

**Issue**: "Could not locate the provided keychain"
- **Root Cause**: Keychain created in wrong location (RUNNER_TEMP instead of ~/Library/Keychains)
- **Solution**: This workflow uses correct location. See `docs/TROUBLESHOOTING.md` for details.

**Issue**: "Code signing failed"
- **Root Cause**: App Store Connect credentials invalid or expired
- **Solution**: Regenerate App Store Connect key and update secrets

**Issue**: "Fastlane version mismatch"
- **Root Cause**: Using wrong Fastlane version (>2.230.0)
- **Solution**: Always use Fastlane 2.230.0 (specified in workflow)

---

## Android Build & Distribution (`android-build.yml`)

Handles building and distributing Flutter Android apps to Google Play Console.

### Inputs

```yaml
inputs:
  project_name:
    type: string
    required: true
  mobile_dir:
    type: string
    default: "packages/mobile"
  build_type:
    type: string
    description: debug | release
    required: true
  release_notes:
    type: string
  java_version:
    type: string
    default: "17"
  flutter_channel:
    type: string
    default: "stable"
```

### Required Secrets

```yaml
secrets:
  firebase_service_account_key:    # Firebase service account JSON (optional)
  google_play_key_json:            # Google Play service account JSON (for release)
```

### What It Does

1. **Environment Setup**
   - Configures runner environment
   - Sets up Git for HTTPS

2. **Flutter & Java**
   - Installs Flutter (stable)
   - Gets dependencies
   - Sets up Java 17
   - Sets up Android SDK

3. **Build Process**
   - Generates Android platform files
   - Builds APK (debug or release)
   - Builds App Bundle (release only)

4. **Artifact Collection**
   - Collects APK files
   - Collects App Bundle files
   - Uploads as GitHub artifacts

### Usage in Project

```yaml
uses: mnelson3/nelson-grey/.github/workflows/reusable/android-build.yml@develop
with:
  project_name: "vehicle-vitals"
  build_type: "release"
secrets:
  google_play_key_json: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
```

---

## Web Deployment (`web-deploy.yml`)

Handles building and deploying web apps to Firebase Hosting.

### Inputs

```yaml
inputs:
  project_name:
    type: string
    required: true
  web_dir:
    type: string
    default: "packages/web"
  environment:
    type: string
    description: development | staging | production
    required: true
  build_command:
    type: string
    default: "npm run build"
  node_version:
    type: string
    default: "18"
```

### Required Secrets

```yaml
secrets:
  firebase_token:              # Firebase CI token (from `firebase login:ci`)
  firebase_project_dev:        # Firebase project ID for dev
  firebase_project_staging:    # Firebase project ID for staging
  firebase_project_prod:       # Firebase project ID for production
```

### What It Does

1. **Environment Setup**
   - Configures Node.js environment
   - Installs Firebase CLI

2. **Build Process**
   - Installs dependencies (`npm ci`)
   - Builds web app (customizable command)

3. **Environment Configuration**
   - Determines Firebase project based on environment
   - Loads environment-specific config file

4. **Deployment**
   - Deploys to Firebase Hosting
   - Uses correct Firebase project per environment
   - Non-interactive deployment with full error handling

### Usage in Project

```yaml
uses: mnelson3/nelson-grey/.github/workflows/reusable/web-deploy.yml@develop
with:
  project_name: "vehicle-vitals"
  environment: "staging"
secrets:
  firebase_token: ${{ secrets.FIREBASE_TOKEN }}
  firebase_project_dev: ${{ secrets.FIREBASE_PROJECT_DEV }}
  firebase_project_staging: ${{ secrets.FIREBASE_PROJECT_STAGING }}
  firebase_project_prod: ${{ secrets.FIREBASE_PROJECT_PROD }}
```

### Environment Mapping

| Input | Firebase Project | Config File | Deployment Target |
|-------|------------------|-------------|--------------------|
| `development` | `firebase_project_dev` | `firebase.dev.json` | Dev hosting |
| `staging` | `firebase_project_staging` | `firebase.staging.json` | Staging hosting |
| `production` | `firebase_project_prod` | `firebase.prod.json` | Production hosting |

---

## Firebase Deployment (`firebase-deploy.yml`)

Handles deploying Firebase Functions, Firestore Rules, and Indexes.

### Inputs

```yaml
inputs:
  project_name:
    type: string
    required: true
  functions_dir:
    type: string
    default: "packages/functions"
  environment:
    type: string
    description: development | staging | production
    required: true
  node_version:
    type: string
    default: "18"
  deploy_rules:
    type: boolean
    default: false
    description: Deploy Firestore rules and indexes
```

### Required Secrets

```yaml
secrets:
  firebase_token:              # Firebase CI token
  firebase_project_dev:        # Firebase project ID for dev
  firebase_project_staging:    # Firebase project ID for staging
  firebase_project_prod:       # Firebase project ID for production
```

### What It Does

1. **Environment Setup**
   - Installs Node.js and Firebase CLI

2. **Build Functions**
   - Installs dependencies
   - Runs build (if available)

3. **Deploy Functions**
   - Deploys Cloud Functions to Firebase
   - Uses environment-specific project

4. **Deploy Rules (Optional)**
   - If `deploy_rules: true`, deploys Firestore rules
   - Deploys Firestore indexes

### Usage in Project

```yaml
uses: mnelson3/nelson-grey/.github/workflows/reusable/firebase-deploy.yml@develop
with:
  project_name: "wishlist-wizard"
  environment: "staging"
  deploy_rules: true
secrets:
  firebase_token: ${{ secrets.FIREBASE_TOKEN }}
  firebase_project_dev: ${{ secrets.FIREBASE_PROJECT_DEV }}
  firebase_project_staging: ${{ secrets.FIREBASE_PROJECT_STAGING }}
  firebase_project_prod: ${{ secrets.FIREBASE_PROJECT_PROD }}
```

---

## Chrome Extension Build & Submit (`chrome-extension-submit.yml`)

Handles building and submitting Chrome extensions to Web Store.

### Inputs

```yaml
inputs:
  project_name:
    type: string
    required: true
  extension_dir:
    type: string
    default: "packages/browser-extension"
  publish:
    type: boolean
    default: false
    description: Auto-publish after upload
  node_version:
    type: string
    default: "18"
```

### Required Secrets

```yaml
secrets:
  chrome_extension_id:     # Chrome Web Store extension ID
  chrome_client_id:        # OAuth client ID
  chrome_client_secret:    # OAuth client secret
  chrome_refresh_token:    # OAuth refresh token
```

### What It Does

1. **Environment Setup**
   - Installs Node.js

2. **Build Extension**
   - Installs dependencies
   - Builds extension (runs `npm run build`)

3. **Package Extension**
   - Copies dist files
   - Copies manifest.json and icons
   - Creates zip package

4. **Submit to Web Store**
   - Uploads zip to Chrome Web Store
   - Auto-publishes if specified
   - Stores artifact for reference

### Usage in Project

```yaml
uses: mnelson3/nelson-grey/.github/workflows/reusable/chrome-extension-submit.yml@develop
with:
  project_name: "wishlist-wizard"
  publish: false
secrets:
  chrome_extension_id: ${{ secrets.CHROME_EXTENSION_ID }}
  chrome_client_id: ${{ secrets.CHROME_CLIENT_ID }}
  chrome_client_secret: ${{ secrets.CHROME_CLIENT_SECRET }}
  chrome_refresh_token: ${{ secrets.CHROME_REFRESH_TOKEN }}
```

---

## Master Pipeline Orchestration (`master-pipeline.yml`)

Meta-workflow that coordinates all platform-specific workflows based on project configuration.

### How It Works

1. **Reads Project Manifest**
   - Loads `.cicd/projects/[project-name].yml`
   - Determines which platforms to build

2. **Determines Trigger Context**
   - `workflow_dispatch`: User manually triggered
   - `push` to `main`: Production deployment
   - `push` to `staging`: Staging deployment
   - `push` to `develop`: Development build
   - `pull_request`: Test only

3. **Dispatches Appropriate Workflows**
   - Mobile (iOS/Android) if enabled
   - Web if enabled
   - Firebase if enabled
   - Chrome extension if enabled

4. **Generates Summary**
   - Shows all build statuses
   - Reports overall pipeline success

### Using in Your Project

Create a minimal `.github/workflows/main.yml` in your project:

```yaml
name: CI/CD Pipeline

on:
  workflow_dispatch:
    inputs:
      action:
        type: choice
        options: [build_all, test_all, build_and_deploy, deploy_only]
      environment:
        type: choice
        options: [development, staging, production]
        default: development
  push:
    branches: [develop, staging, main]
  pull_request:
    branches: [develop, staging, main]

jobs:
  master-pipeline:
    uses: mnelson3/nelson-grey/.github/workflows/reusable/master-pipeline.yml@develop
```

That's it! The master pipeline handles everything based on your project manifest.

---

## Secrets Configuration

### Required Secrets by Project Type

**All Projects**
- `FIREBASE_TOKEN` - Get via: `firebase login:ci`

**Mobile Projects (iOS/Android)**
- `APP_STORE_CONNECT_KEY_ID` - From Apple Developer Account
- `APP_STORE_CONNECT_ISSUER_ID` - From Apple Developer Account
- `APP_STORE_CONNECT_KEY` - Private key P8 file (base64 encoded)
- `MATCH_PASSWORD` - Password for match certificate repository
- `MATCH_GIT_URL` - GitHub URL of match certificates repo
- `MATCH_GIT_BRANCH` - Branch containing certificates

**Web Projects**
- `FIREBASE_PROJECT_DEV` - Firebase project ID for development
- `FIREBASE_PROJECT_STAGING` - Firebase project ID for staging
- `FIREBASE_PROJECT_PROD` - Firebase project ID for production

**Chrome Extension Projects**
- `CHROME_EXTENSION_ID` - From Chrome Web Store
- `CHROME_CLIENT_ID` - OAuth credentials from Google Cloud
- `CHROME_CLIENT_SECRET` - OAuth credentials from Google Cloud
- `CHROME_REFRESH_TOKEN` - OAuth refresh token

### Setting Up Secrets

1. **In GitHub Repository**:
   - Go to Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Add each required secret

2. **For Sensitive Data**:
   - Use base64 encoding for binary/JSON data
   - Never commit secrets to repository
   - Rotate regularly

3. **Using Environment Secrets**:
   - Create environment-specific secrets for production
   - GitHub will enforce approval workflows for protected environments

---

## Best Practices

### 1. Version Control
- Always reference workflows from a specific branch or tag: `@develop`, `@main`
- Never use `@master` as it may not exist
- Update branch reference when major changes occur

### 2. Error Handling
- All workflows include detailed error reporting
- Check `$GITHUB_STEP_SUMMARY` for detailed logs
- Review `docs/TROUBLESHOOTING.md` for common issues

### 3. Performance
- Use `cache: 'npm'` for Node.js projects
- Avoid unnecessary rebuild steps
- Leverage GitHub's caching mechanisms

### 4. Monitoring
- Review workflow runs in GitHub Actions tab
- Set up notifications for failures
- Monitor build times and optimize as needed

### 5. Testing
- Test workflows locally with `act` tool
- Use `--dry-run` flags when available
- Start with `build_only` before deploying

---

## Migration Guide: Existing to Reusable

### Before (Old: 400+ line workflow per project)
```yaml
name: iOS Distribution
on: [workflow_dispatch]
jobs:
  build-ios:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - name: Setup Flutter
        # ... 20 steps of setup
      - name: Build
        # ... 15 steps of building
      - name: Deploy
        # ... 10 steps of deploying
```

### After (New: Minimal with reusable workflow)
```yaml
name: CI/CD Pipeline
on: [workflow_dispatch, push, pull_request]
jobs:
  pipeline:
    uses: mnelson3/nelson-grey/.github/workflows/reusable/master-pipeline.yml@develop
```

**Reduction**: 400+ lines → 10 lines
**Consistency**: 100% across all projects
**Maintenance**: Centralized in nelson-grey

---

## Troubleshooting

### Workflow Not Found
**Error**: `Error: Could not find workflow file`
- **Solution**: Ensure branch reference is correct (`@develop` vs `@main`)
- **Check**: Workflow file exists in nelson-grey repository

### Secrets Not Accessible
**Error**: `Error: Secrets are not available`
- **Solution**: Repository/environment secrets not set correctly
- **Check**: Settings → Secrets and variables → Actions
- **Verify**: Secret names match exactly (case-sensitive)

### Build Failures
**Error**: Various build-related errors
- **Solution**: See `docs/TROUBLESHOOTING.md` for specific error
- **Steps**: Check logs, verify configuration, run locally with `act`

### Timeout Issues
**Error**: `Job exceeded maximum execution time`
- **Solution**: Increase runner resources or optimize build
- **Check**: .github/workflows logs for slow steps

---

## Support & Questions

- **Documentation**: See nelson-grey `docs/` folder
- **Troubleshooting**: See `docs/TROUBLESHOOTING.md`
- **Configuration**: See `.cicd/projects/` examples
- **Architecture**: See `docs/ARCHITECTURE.md` for design rationale

---

**Last Updated**: Phase 2 Implementation
**Reusable Workflows Version**: 1.0
**Status**: Production Ready
