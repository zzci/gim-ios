# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Element X iOS is a Matrix messaging client built with SwiftUI, using the Matrix Rust SDK via Swift bindings. The Xcode project is generated from `project.yml` using XcodeGen — never edit `ElementX.xcodeproj` directly.

## Build & Development

```bash
# Initial setup (requires Homebrew)
swift run tools setup-project

# Regenerate Xcode project after changing project.yml or target.yml files
xcodegen

# Build the Rust SDK locally for development
swift run tools build-sdk

# Format code
swiftformat .

# Check for outdated packages
swift run tools outdated-packages
```

## Testing

```bash
# Unit tests + preview snapshot tests
bundle exec fastlane unit_tests

# Unit tests only (skip preview tests)
bundle exec fastlane unit_tests skip_previews:true

# UI tests (must specify device)
bundle exec fastlane ui_tests device:iPhone
bundle exec fastlane ui_tests device:iPad

# Run a single UI test
bundle exec fastlane ui_tests device:iPhone test_name:MyTestClass/testMethodName

# Accessibility tests
bundle exec fastlane accessibility_tests

# Integration tests
bundle exec fastlane integration_tests
```

Snapshot tests use Git LFS. Snapshots are stored in `Sources/__Snapshots__` within each test target's folder.

## Architecture: MVVM-Coordinator

Every screen follows this structure (5 files + 1 test file):

| File | Purpose |
|---|---|
| `*Models.swift` | `ViewState` (struct), `ViewAction` (enum), `ViewModelAction` (enum), `ViewStateBindings` (struct) |
| `*ViewModelProtocol.swift` | Protocol for the ViewModel (enables mocking) |
| `*ViewModel.swift` | Business logic; processes `ViewAction`s, emits `ViewModelAction`s via `actionsPublisher` |
| `*Screen.swift` | SwiftUI view; receives `context` from ViewModel |
| `*Coordinator.swift` | Creates ViewModel, subscribes to `actionsPublisher`, emits `CoordinatorAction`s for navigation |
| `*ViewModelTests.swift` | Unit tests |

**ViewModel base class:** `StateStoreViewModelV2<State, ViewAction>` (uses `@Observable`). The ViewModel exposes a `context` object to views — views never access the ViewModel directly.

**Creating a new screen:**
```bash
./Tools/Scripts/createScreen.sh FolderName MyScreenName
xcodegen  # regenerate project after
```

### Key architectural layers

- **FlowCoordinators** (`ElementX/Sources/FlowCoordinators/`): Manage navigation flows (auth, room, settings). Use `SwiftState` state machines for complex transitions.
- **Services** (`ElementX/Sources/Services/`): ~29 service modules (Authentication, Room, Timeline, Media, Analytics, etc.). All protocol-based for testability.
- **Screens** (`ElementX/Sources/Screens/`): 56+ screens following the pattern above.
- **AppCoordinator**: Root coordinator orchestrating the entire app lifecycle.

## Code Conventions

**Enforced by SwiftLint (errors, not just warnings):**
- Use `MXLog` instead of `print()`, `println()`, or `os_log()`
- Use `ElementNavigationStack` instead of `NavigationStack`
- Specify explicit `spacing:` parameter on `VStack` and `HStack`
- Don't convert Compound colors via `UIColor(.compound...)` — use UIColor tokens directly
- Max function body: 100 lines

**Strings/Translations:**
- Never edit `Localizable.strings`, `Localizable.stringsdict`, or `InfoPlist.strings` directly
- Add new English strings to `Untranslated.strings` / `Untranslated.stringsdict`
- Translations are managed via Localazy (shared with Element X Android)

**Project configuration:**
- Edit `project.yml` (or included `target.yml` files) instead of modifying the Xcode project
- Run `xcodegen` after any YAML config changes
- Deployment target: iOS 18.5
- License header: AGPL-3.0-only OR LicenseRef-Element-Commercial

## Key Files

- `project.yml` — XcodeGen project definition, all packages/dependencies listed here
- `app.yml` — App-specific settings (bundle ID, team, entitlements)
- `ElementX/Sources/Application/AppCoordinator.swift` — Main app flow orchestrator
- `ElementX/Sources/Application/Settings/AppSettings.swift` — Feature flags and app configuration
- `ElementX/Sources/Other/SwiftUI/ViewModel/StateStoreViewModelV2.swift` — ViewModel base class

## Targets

- **ElementX** — Main app
- **NSE** — Notification Service Extension
- **ShareExtension** — Share extension
- **UnitTests, PreviewTests, UITests, AccessibilityTests, IntegrationTests** — Test targets
- **SDKMocks** — Shared mock types for the Matrix Rust SDK
