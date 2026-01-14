# Project Manifest Format Reference

**Version**: 1.0  
**Format**: YAML  
**Location**: `.cicd/projects/<project-name>.yml`

---

## Overview

Project manifests define how to build, test, and deploy a project in the CI/CD pipeline. They replace verbose workflow YAML files and enable reusable, parameterized workflows.

---

## Structure

### Root Sections

```yaml
project:        # Project metadata
targets:        # Build targets (iOS, Android, Web, Docker, Firebase)
ci:             # CI/CD configuration
notifications:  # Notification settings
```

---

## Project Section

```yaml
project:
  name: "modulo-squares"              # Required: matches repo name
  description: "Project description"  # Optional
  owner: "mnelson3"                   # Optional: GitHub org/user (default: nelsongrey)
```

**Rules**:
- `name` must match repository name (lowercase, hyphens only)
- `name` used as identifier throughout pipeline

---

## Targets Section

Defines which platforms this project supports and how to build/deploy them.

### iOS Target

```yaml
targets:
  ios:
    enabled: true                      # Include in CI/CD pipeline
    
    schemes:
      - name: "Main App"               # Xcode scheme name
        path: "packages/mobile/ios"    # Path to iOS project
        configuration: "Release"       # Build configuration
    
    signing:
      team_id: "${APPLE_TEAM_ID}"     # Apple Developer Team ID (env variable)
      bundle_id: "com.example.app"    # App bundle ID
      profiles:
        development: true              # Create development profile
        distribution: true             # Create distribution profile
    
    destinations:
      testflight:
        enabled: true                  # Upload to TestFlight
        group: "Internal Testers"      # TestFlight beta group
      appstore:
        enabled: true                  # Can submit to App Store
```

**Environment Variables**:
- `${APPLE_TEAM_ID}`: Set in GitHub organization secrets
- Will be substituted at runtime

**Signing Profiles**:
- `development`: For ad-hoc and development builds
- `distribution`: For TestFlight and App Store releases

**Destinations**:
- `testflight`: Automatic upload to TestFlight (requires ASC credentials)
- `appstore`: Can manually submit, or auto-submit if configured

---

### Android Target

```yaml
targets:
  android:
    enabled: true
    
    path: "packages/mobile/android"    # Path to Android project
    
    signing:
      keystore_ref: "${ANDROID_KEYSTORE_PATH}"  # Path to keystore file
      key_alias: "${ANDROID_KEY_ALIAS}"         # Key alias in keystore
      # Also uses: ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_PASSWORD from secrets
    
    destinations:
      firebase_app_distribution:
        enabled: true                  # Upload to Firebase App Distribution
        groups:
          - testers                    # Groups to release to
      google_play:
        enabled: true
        track: "internal"              # Release track (internal, alpha, beta, production)
```

**Keystore**:
- Path should be accessible during build
- Can be stored in repo (not recommended) or injected at runtime
- Format: `file://path/to/keystore.jks` or URL

**Destinations**:
- `firebase_app_distribution`: For beta testing
- `google_play`: For Play Store releases (tracks: internal, alpha, beta, production)

---

### Web Target

```yaml
targets:
  web:
    enabled: true
    
    build_command: "npm run build"     # Command to build the app
    
    destinations:
      firebase_hosting:
        enabled: true                  # Deploy to Firebase Hosting
      github_pages:
        enabled: false                 # Deploy to GitHub Pages
```

**Build Command**:
- Run in project root
- Output should be in `dist/`, `build/`, `out/`, or similar
- Framework-specific (Next.js, React, Vue, etc.)

---

### Docker Target

```yaml
targets:
  docker:
    enabled: true
    
    services:
      - name: "api"                    # Service identifier
        dockerfile: "Dockerfile"       # Dockerfile location
        registry: "docker.io"          # Docker registry (docker.io, ghcr.io, etc.)
        image_name: "wishlist-wizard-api"  # Image name (without registry/tags)
        
      - name: "web"
        dockerfile: "web.Dockerfile"
        registry: "docker.io"
        image_name: "wishlist-wizard-web"
```

**Registry Options**:
- `docker.io`: Docker Hub
- `ghcr.io`: GitHub Container Registry
- `public.ecr.aws`: AWS ECR Public
- Custom registry URLs

**Image Name**:
- Without registry prefix (added automatically)
- Tags (latest, version) added by workflow
- Credentials from `DOCKER_USERNAME`, `DOCKER_PASSWORD` secrets

---

### Firebase Target

```yaml
targets:
  firebase:
    enabled: true
    
    project_id: "modulo-squares-prod"  # Firebase project ID
    
    hosting:
      enabled: true                    # Deploy web app to Firebase Hosting
    
    functions:
      enabled: true                    # Deploy Cloud Functions
      paths:                           # Paths to deploy
        - "functions"
    
    firestore:
      deploy_rules: true               # Deploy Firestore security rules
      deploy_indexes: true             # Deploy Firestore composite indexes
```

**Project ID**:
- From Firebase console
- Can vary per environment (dev/staging/prod)

**Hosting**:
- For web apps
- Uses `firebase.json` configuration

**Functions**:
- Paths to functions code relative to project root
- Auto-detected from `functions/` directory if not specified

**Firestore**:
- Requires `firestore.rules` file
- Requires `firestore.indexes.json` for indexes

---

## CI Section

Configuration for continuous integration behavior.

### Runners

```yaml
ci:
  runners:
    macos:
      labels:              # GitHub Actions labels
        - self-hosted      # Must use self-hosted runner
        - macOS            # macOS OS
        - ios              # iOS builds
      required: true       # Build cannot succeed without this runner
    
    docker:
      labels:
        - self-hosted
        - docker
      required: false      # Docker builds are optional
```

**Labels**:
- Workflow uses these to find appropriate runner
- Multiple labels must ALL match (AND logic)
- Examples:
  - `[self-hosted, macOS]` → self-hosted macOS runner
  - `[self-hosted, Docker]` → self-hosted Docker runner
  - `ubuntu-latest` → GitHub-hosted runner

**Required**:
- `true`: Build fails if runner unavailable
- `false`: Skipped gracefully if runner unavailable

---

### Triggers

```yaml
ci:
  triggers:
    - event: push              # Trigger on push
      branches:
        - develop
      paths:                   # Only if these paths changed
        - "packages/mobile/**"
        - ".github/workflows/**"
        - "pubspec.yaml"
    
    - event: pull_request      # Trigger on PR
      branches:
        - develop
        - staging
        - main
      paths:
        - "packages/**"
    
    - event: workflow_dispatch # Manual trigger
```

**Events**:
- `push`: On git push to specified branches
- `pull_request`: On PR opened/updated for specified branches
- `workflow_dispatch`: Manual trigger via GitHub UI

**Branches**:
- List of branches that trigger this
- Supports wildcards: `release/*`

**Paths**:
- File paths that trigger workflow when changed
- Glob patterns supported: `packages/**/lib/**`
- If any path matches, workflow runs
- Empty = all changes trigger (no filtering)

---

### Environment

```yaml
ci:
  environment:
    development:
      firebase_config: "firebase.dev.json"    # Firebase config file
      secrets_profile: "dev"                  # Secrets profile name
    
    staging:
      firebase_config: "firebase.staging.json"
      secrets_profile: "staging"
    
    production:
      firebase_config: "firebase.prod.json"
      secrets_profile: "prod"
```

**Environment Profiles**:
- `development`: Unsafe defaults, for development
- `staging`: Production-like, for testing
- `production`: Production settings, restricted access

**Firebase Config**:
- JSON file from Firebase console
- Different project IDs per environment
- Injected at build time

**Secrets Profile**:
- Maps to GitHub organization secret patterns
- Example: `${FIREBASE_${ENV}_PROJECT_ID}` becomes `${FIREBASE_DEV_PROJECT_ID}`

---

## Notifications Section

```yaml
notifications:
  slack_webhook: "${SLACK_WEBHOOK_URL}"      # Slack channel webhook
  failure_recipients:                        # Email on failure
    - "team@example.com"
    - "on-call@example.com"
```

**Slack**:
- Webhook URL from Slack app
- Notifies on build success/failure
- Includes links to logs and artifacts

**Email**:
- Notified on workflow failure only
- Requires email service configuration

---

## Environment Variables in Manifests

### Substitution Rules

```yaml
# Variables wrapped in ${ } are substituted at runtime
team_id: "${APPLE_TEAM_ID}"           # From GitHub secret

# Literal strings are used as-is
bundle_id: "com.example.app"

# Environment-specific substitution
firebase_config: "firebase.${ENV}.json"  # → firebase.dev.json (in dev)
```

### Available Variables

**GitHub Secrets** (all organization secrets available):
- `${APPLE_TEAM_ID}`
- `${ASC_KEY_ID}`
- `${FIREBASE_TOKEN}`
- Any custom secret: `${MY_CUSTOM_SECRET}`

**Built-in Variables**:
- `${ENV}` → development | staging | production
- `${PROJECT}` → project name
- `${GITHUB_SHA}` → git commit SHA
- `${GITHUB_REF}` → git branch/tag

**Bash-style** (expanded in shell):
- `${HOME}` → home directory
- `${USER}` → username

---

## Complete Example

```yaml
project:
  name: "vehicle-vitals"
  description: "Vehicle management app with web and mobile clients"
  owner: "nelsongrey"

targets:
  ios:
    enabled: true
    schemes:
      - name: "Vehicle Vitals"
        path: "packages/mobile/ios"
        configuration: "Release"
    signing:
      team_id: "${APPLE_TEAM_ID}"
      bundle_id: "com.nelsongrey.vehiclevitals"
      profiles:
        development: true
        distribution: true
    destinations:
      testflight:
        enabled: true
        group: "Internal Testers"
      appstore:
        enabled: true

  android:
    enabled: true
    path: "packages/mobile/android"
    signing:
      keystore_ref: "${ANDROID_KEYSTORE_PATH}"
      key_alias: "${ANDROID_KEY_ALIAS}"
    destinations:
      firebase_app_distribution:
        enabled: true
        groups:
          - testers
      google_play:
        enabled: true
        track: "internal"

  web:
    enabled: true
    build_command: "cd packages/web && npm run build"
    destinations:
      firebase_hosting:
        enabled: true

  firebase:
    enabled: true
    project_id: "vehicle-vitals-prod"
    hosting:
      enabled: true
    functions:
      enabled: false
    firestore:
      deploy_rules: true
      deploy_indexes: true

ci:
  runners:
    macos:
      labels:
        - self-hosted
        - macOS
        - ios
      required: true
    docker:
      labels:
        - self-hosted
        - docker
      required: false

  triggers:
    - event: push
      branches:
        - develop
      paths:
        - "packages/mobile/**"
        - "packages/web/**"
        - ".github/workflows/**"

    - event: pull_request
      branches:
        - develop
        - staging
        - main

    - event: workflow_dispatch

  environment:
    development:
      firebase_config: "firebase.dev.json"
      secrets_profile: "dev"
    staging:
      firebase_config: "firebase.staging.json"
      secrets_profile: "staging"
    production:
      firebase_config: "firebase.prod.json"
      secrets_profile: "prod"

notifications:
  slack_webhook: "${SLACK_WEBHOOK_URL}"
  failure_recipients:
    - "team@example.com"
```

---

## Validation

### Schema Validation

```bash
# Validate manifest against schema
yq eval-all '.project' .cicd/projects/vehicle-vitals.yml | \
  ajv validate -d - -s .cicd/schemas/project-manifest.schema.json

# Or use built-in validator
./scripts/validate-config.sh vehicle-vitals
```

### Manual Checks

```bash
# Ensure project name matches repo
grep "name:" .cicd/projects/vehicle-vitals.yml

# Ensure all required keys present
grep -E "project|targets|ci" .cicd/projects/vehicle-vitals.yml

# Check syntax
yq eval '.' .cicd/projects/vehicle-vitals.yml > /dev/null && echo "Valid YAML"
```

---

## Common Patterns

### iOS + Android + Web (Standard Mobile App)

```yaml
targets:
  ios:
    enabled: true
    # ... iOS config
  android:
    enabled: true
    # ... Android config
  web:
    enabled: true
    build_command: "npm run build"
  firebase:
    enabled: true
    hosting:
      enabled: true
```

### Web Only (React/Vue/Next.js)

```yaml
targets:
  web:
    enabled: true
    build_command: "npm run build"
    destinations:
      firebase_hosting:
        enabled: true
  # No iOS/Android
```

### Microservices (Multiple Docker Services)

```yaml
targets:
  docker:
    enabled: true
    services:
      - name: "api"
        dockerfile: "api/Dockerfile"
        image_name: "myapp-api"
      - name: "web"
        dockerfile: "web/Dockerfile"
        image_name: "myapp-web"
      - name: "worker"
        dockerfile: "worker/Dockerfile"
        image_name: "myapp-worker"
```

### Firebase Functions Only

```yaml
targets:
  firebase:
    enabled: true
    functions:
      enabled: true
      paths:
        - "functions"
    hosting:
      enabled: false
    firestore:
      deploy_rules: false
```

---

## Migration Guide

### From Old Workflow YAML to Manifest

**Before** (old way):
```yaml
# .github/workflows/ios-app-distribution.yml (400+ lines)
name: iOS Distribution
on:
  push:
    branches: [develop]
  pull_request:
    branches: [main]
jobs:
  build-ios:
    runs-on: [self-hosted, macOS, ios]
    # ... 300+ lines of workflow steps
```

**After** (new way):
```yaml
# .cicd/projects/modulo-squares.yml (50 lines)
project:
  name: modulo-squares
targets:
  ios:
    enabled: true
    # ... configuration
ci:
  triggers:
    - event: push
      branches: [develop]
    - event: pull_request
      branches: [main]
```

**Workflow (20 lines)**:
```yaml
# .github/workflows/main.yml
name: CI/CD
on: [push, pull_request, workflow_dispatch]
jobs:
  build:
    uses: mnelson3/nelson-grey/.github/workflows/reusable/main.yml@main
    with:
      project: modulo-squares
    secrets: inherit
```

---

## Debugging

### View Parsed Manifest

```bash
# Convert to JSON for inspection
yq eval -o json .cicd/projects/modulo-squares.yml

# Extract specific section
yq eval '.targets.ios' .cicd/projects/modulo-squares.yml

# Check if key exists
yq eval 'has("targets")' .cicd/projects/modulo-squares.yml
```

### Test Variable Substitution

```bash
# Test environment variable substitution
APPLE_TEAM_ID="A123B456CD" \
  yq eval '.targets.ios.signing.team_id' .cicd/projects/modulo-squares.yml

# Should output: A123B456CD (or ${APPLE_TEAM_ID} if substitution not configured)
```

---

## Related Documentation

- [Architecture Overview](./ARCHITECTURE.md)
- [Setup Instructions](./SETUP.md)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)
- [Schema Definition](../.cicd/schemas/project-manifest.schema.json)
