# Nelson Grey - Shared Resources & Certificates

This repository contains shared resources, certificates, and utilities used across multiple Nelson Grey projects.

## Structure

### certs/
Contains all certificates with their private keys for iOS/macOS application signing.

### profiles/
Contains all provisioning profiles for iOS/macOS applications.

### shared/
Contains shared utilities and libraries used across multiple projects:

#### github-auth/
GitHub CLI authentication library for automated GitHub Actions runner token management
- `github-auth-lib.sh`: Shared bash functions for GitHub CLI authentication, token generation, and validation

## Usage

### Certificates & Profiles
This repository is managed by [fastlane match](https://docs.fastlane.tools/actions/match/) for automated certificate and provisioning profile management.

**Important:** Make sure this repository is set to private and only team members have access.

### Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using bundler by following instructions here on [fastlane docs](https://docs.fastlane.tools).

or alternatively using 

`brew install fastlane`

### Usage

Navigate to your project folder and run

```
fastlane match appstore
```

```
fastlane match adhoc
```

```
fastlane match development
```

```
fastlane match enterprise
```

### Shared Libraries

The `shared/` directory contains reusable code libraries:

- **GitHub Auth Library**: Used by token-refresh.sh scripts in various projects for automated GitHub Actions runner management

For more information open [fastlane match git repo](https://docs.fastlane.tools/actions/match/)
