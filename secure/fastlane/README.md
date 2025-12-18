fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios development

```sh
[bundle exec] fastlane ios development
```

Fetch development certificates and profiles

### ios distribution

```sh
[bundle exec] fastlane ios distribution
```

Fetch distribution certificates and profiles

### ios sync_all

```sh
[bundle exec] fastlane ios sync_all
```

Sync all (development + distribution)

### ios ci_rotate

```sh
[bundle exec] fastlane ios ci_rotate
```

CI: rotate certificates if needed (runs match and pushes to match repo)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
