# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GIM is a Matrix messaging client built with SwiftUI, using the Matrix Rust SDK via Swift bindings. It is a fork of Element X iOS, rebranded for the GIM platform. The Xcode project is generated from `project.yml` using XcodeGen — never edit `ElementX.xcodeproj` directly.

## Build & Development

```bash
# Initial setup (requires Homebrew) — installs brew deps, configures githooks, runs xcodegen
swift run tools setup-project

# Regenerate Xcode project after changing project.yml or target.yml files
xcodegen

# Build the Rust SDK locally for development
swift run tools build-sdk

# Format code
swiftformat .

# Check for outdated packages
swift run tools outdated-packages

# Network debugging: set HTTPS_PROXY env var in Xcode scheme (e.g. localhost:8080 for mitmproxy)
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

Snapshot tests use Git LFS. Snapshots are stored in `Sources/__Snapshots__` within each test target's folder. Preview tests run on iPhone SE (3rd generation); UI tests run on iPhone 17 / iPad A16 simulators (iOS 26.1).

## Architecture: MVVM-Coordinator

Every screen follows this structure (5 files + 1 test file):

| File | Purpose |
|---|---|
| `*Models.swift` | `ViewState` (struct), `ViewAction` (enum), `ViewModelAction` (enum), `ViewStateBindings` (struct) |
| `*ViewModelProtocol.swift` | Protocol for the ViewModel (enables mocking) |
| `*ViewModel.swift` | Business logic; processes `ViewAction`s, emits `ViewModelAction`s via `actionsPublisher` |
| `*Screen.swift` | SwiftUI view; receives `context` from ViewModel |
| `*Coordinator.swift` | Creates ViewModel, subscribes to `actionsPublisher`, emits `CoordinatorAction`s for navigation |
| `*ViewModelTests.swift` | Unit tests (in `UnitTests/Sources/`) |

**Creating a new screen:**
```bash
./Tools/Scripts/createScreen.sh FolderName MyScreenName
xcodegen  # regenerate project after
```

### ViewModel pattern details

**Base class:** `StateStoreViewModelV2<State, ViewAction>` (uses `@Observable`). The ViewModel exposes a `context` object to views — views never access the ViewModel directly.

**Context uses `@dynamicMemberLookup`** for two-way bindings:
- Read-only state: `context.viewState.someProperty`
- Mutable bindings: `$context.someBindingProperty` (via `@Bindable var context`)
- Send actions: `context.send(viewAction: .someAction)`

**State split:** `ViewState` holds read-only data; `ViewStateBindings` (conforming to `BindableState`) holds mutable UI state (text fields, toggles). If no bindings needed, use `BindableState` with `BindStateType = Void`.

**Action chain:** View sends `ViewAction` → ViewModel processes in `process(viewAction:)` → ViewModel emits `ViewModelAction` via `actionsSubject.send()` → Coordinator subscribes via `actionsPublisher` → Coordinator emits `CoordinatorAction` for parent.

### Key architectural layers

- **AppCoordinator** (`ElementX/Sources/Application/AppCoordinator.swift`): Root coordinator orchestrating the entire app lifecycle — authentication, session restoration, app lock, background refresh. Uses `AppCoordinatorStateMachine` with states: initial → signedOut/signedIn/signingOut/restoringSession.
- **FlowCoordinators** (`ElementX/Sources/FlowCoordinators/`): Manage navigation flows (auth, room, settings). Use `SwiftState` state machines with `indirect enum State: StateType` and `.addTransitionHandler()` for complex transitions. `tryEvent()` silently ignores invalid transitions.
- **Services** (`ElementX/Sources/Services/`): ~29 service modules (Authentication, Room, Timeline, Media, Analytics, etc.). All protocol-based for testability. Protocols marked `// sourcery: AutoMockable` get auto-generated mocks.
- **Screens** (`ElementX/Sources/Screens/`): 56+ screens following the MVVM pattern above.

### Dependency injection

- **`CommonFlowParameters`**: Bundles dependencies flowing DOWN the coordinator hierarchy. Each flow extracts what it needs. Do NOT pass directly to screen coordinators.
- **`ServiceLocator`**: Minimal — only 3 services: `userIndicatorController`, `settings`, `analytics`. Accessed via `ServiceLocator.shared`.
- **`AppHooks`**: Plugin architecture for forks. Hooks registered in `AppCoordinator.init()` before anything else. Includes hooks for: appSettings, compound, bugReport, clientBuilder, remoteSettings.

### Threading

- `@MainActor` is used extensively on ViewModels, Coordinators, and UI code.
- Rust SDK calls are wrapped in `Task { await ... }` to hop threads.
- Combine subscriptions must be stored: `.store(in: &cancellables)`.

### Mock generation

- Service protocols with `// sourcery: AutoMockable` → auto-generated mocks in `GeneratedMocks.swift`.
- `SDKMocks/` contains generated mocks for `MatrixRustSDK` classes.
- Generated mocks are `@unchecked Sendable` for concurrent test execution.

## Code Conventions

**Enforced by SwiftLint (errors, not just warnings):**
- Use `MXLog` instead of `print()`, `println()`, or `os_log()`
- Use `ElementNavigationStack` instead of `NavigationStack` (in `ElementX/Sources/` only)
- Specify explicit `spacing:` parameter on `VStack` and `HStack`
- Don't convert Compound colors via `UIColor(.compound...)` — use UIColor tokens directly
- Max function body: 100 lines
- Force unwrapping is opt-in linted

**SwiftFormat config (`.swiftformat`):**
- `--wraparguments after-first` / `--wrapparameters after-first`
- `--commas inline`
- `--stripunusedargs closure-only`
- Excludes `**/Sources/**/Generated`

**Strings/Translations:**
- Never edit `Localizable.strings`, `Localizable.stringsdict`, or `InfoPlist.strings` directly
- Add new English strings to `Untranslated.strings` / `Untranslated.stringsdict`
- Translations are managed via Localazy (shared with Element X Android)

**Project configuration:**
- Edit `project.yml` (or included `target.yml` files) instead of modifying the Xcode project
- Run `xcodegen` after any YAML config changes
- Deployment target: iOS 18.5
- License header: AGPL-3.0-only OR LicenseRef-Element-Commercial
- Versioning: `MARKETING_VERSION` in project.yml uses `YY.MM.patch` format

**PR conventions (enforced by Danger):**
- PRs > 1000 additions get a warning
- Must have description body
- View changes should include screenshots
- Prefer SVG/PDF over PNG for resource images
- Title must be a complete changelog entry (no `…` suffix, no `Fixes #123` prefix)
- Must have exactly one `pr-` label for changelog categorization

## Key Files

- `project.yml` — XcodeGen project definition, all packages/dependencies listed here
- `app.yml` — App-specific settings (bundle ID, team, display name, app group)
- `ElementX/SupportingFiles/target.yml` — URL schemes, associated domains, entitlements
- `ElementX/Sources/Application/AppCoordinator.swift` — Main app flow orchestrator
- `ElementX/Sources/Application/Settings/AppSettings.swift` — Feature flags and app configuration
- `ElementX/Sources/Application/Settings/OIDCConfiguration.swift` — OIDC/authentication config
- `ElementX/Sources/Other/SwiftUI/ViewModel/StateStoreViewModelV2.swift` — ViewModel base class
- `.swiftlint.yml` — Lint rules (custom rules for MXLog, NavigationStack, spacing, etc.)
- `.swiftformat` — Format rules
- `Dangerfile.swift` — PR checks
- `Tools/Scripts/createScreen.sh` — Screen scaffolding script

## Targets

- **ElementX** — Main app
- **NSE** — Notification Service Extension
- **ShareExtension** — Share extension
- **UnitTests, PreviewTests, UITests, AccessibilityTests, IntegrationTests** — Test targets
- **SDKMocks** — Shared mock types for the Matrix Rust SDK
- **Periphery** — Aggregate target for dead code detection
