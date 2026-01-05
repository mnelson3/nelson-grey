## [fastlane match](https://docs.fastlane.tools/actions/match/)

> Do not modify this file, as it gets overwritten every time you run _match_.

This repository contains all your certificates and provisioning profiles needed to build and sign your applications. They are encrypted using OpenSSL via a passphrase.

**Important:** Make sure this repository is set to private and only your team members have access to this repo.

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

For more information open [fastlane match git repo](https://docs.fastlane.tools/actions/match/)

### Content

#### certs

This directory contains all your certificates with their private keys

#### profiles

This directory contains all provisioning profiles

---

## Shared GitHub Actions Runner

This repository also hosts the configuration for the shared macOS GitHub Actions runner that serves all repositories in the `nelsongrey` organization (e.g., `modulo-squares`, `vehicle-vitals`, `wishlist-wizard`).

### Setup

1.  Run the setup script:
    ```bash
    ./setup-shared-runner.sh
    ```
2.  Enter the registration token when prompted (get it from [GitHub Settings](https://github.com/organizations/nelsongrey/settings/actions/runners/new)).
3.  Install and start the service:
    ```bash
    cd actions-runner
    ./svc.sh install
    ./svc.sh start
    ```

### Maintenance

To check the status or restart the runner:
```bash
cd actions-runner
./svc.sh status
./svc.sh restart
```

For more information open [fastlane match git repo](https://docs.fastlane.tools/actions/match/)
