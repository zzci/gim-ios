# Contributing to GIM iOS

Thank you for your interest in contributing to GIM iOS.

## Setting up a development environment

### Setup Project

It's mandatory to have [homebrew](https://brew.sh/) installed on your mac, and run after the checkout:

```
swift run tools setup-project
```

This will:
- Install various brew dependencies required for the project (like xcodegen).
- Set up git to use the shared githooks from the repo, instead of the default ones.
- Automatically run xcodegen for the first time.

### Xcode

We suggest using an Xcode version later than 15.0.1.

The Xcode project can be directly compiled through the shared GIM scheme which includes the main application as well as the unit and UI tests.

The Xcode project itself is generated through [xcodegen](https://github.com/yonaskolb/XcodeGen) so any changes shouldn't be made directly to it but to the configuration files.

### Dependencies

Dependencies will be automatically fetched through the Swift Package Manager, including a release version of the MatrixRustSDK. If you encounter issues while resolving the package graph please attempt a cache reset through `File -> Packages -> Reset Package Caches`.

To setup the RustSDK in local development mode run the following command

```
swift run tools build-sdk
```

This will clone a copy of the SDK if needed, build it for all supported architectures and configure GIM to use the built framework. To learn about additional options run

```
swift run tools build-sdk --help
```

### Tools

The project depends on some tools for the build process which are normally installed through `swift run tools setup-project`.

Git LFS is used to store UI and Preview test snapshots. `swift run tools setup-project` will already install it, however it can also be installed after a checkout by running:

```
git lfs install
```

### Snapshot Tests

If you make changes to the UI you may cause existing UI and Preview test snapshots to fail. The snapshots are stored under `Sources/__Snapshots__` in their respective target's folder.

### Githooks

The project uses its own shared githooks stored in the .githooks folder, you will need to configure git to use such folder, this is already done if you have run the setup tool with `swift run tools setup-project` otherwise you would need to run:

```
git config core.hooksPath .githooks
```

### Strings and Translations

Please do **not** manually edit the `Localizable.strings`, `Localizable.stringsdict` or `InfoPlist.strings` files! If your PR requires new strings to be added, add the `en` values to `Untranslated.strings`/`Untranslated.stringsdict`.

### Continuous Integration

GIM uses Fastlane for running actions on the CI and tries to keep the configuration confined to either [fastlane](fastlane/Fastfile) or [xcodegen](project.yml).

Please run `bundle exec fastlane` to see available options.

### Network debugging proxy

It's possible to debug the app's network traffic with a proxy server by setting the `HTTPS_PROXY` environment variable in the GIM scheme to the proxy's address (e.g. localhost:8080 for mitmproxy).

## Pull requests

Please open a PR with a clear description of what you have changed and why.

## Implementing a new screen

New screen flows are currently using the MVVM-Coordinator pattern. Please refer to the [create screen template](Tools/Scripts/README.md#create-screen-templates) section.

## Coding style

For Swift coding style we use [SwiftLint](https://github.com/realm/SwiftLint) to check some conventions at compile time (rules are located in the `.swiftlint.yml` file).
Otherwise please have a look to [Apple Swift conventions](https://swift.org/documentation/api-design-guidelines.html#conventions).

We enforce the coding style by running checks on the CI through [SwiftLint](.swiftlint.yml) and [SwiftFormat](.swiftformat).

## Thanks

Thank you for contributing to GIM and the Matrix ecosystem!
