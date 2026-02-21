# GIM iOS - Architecture & Security Audit Document

> **Last Updated:** 2026-02-20
> **Project:** GIM (Element X iOS Fork)
> **Bundle ID:** `im.g.message`
> **Domain:** `g.im`
> **iOS Target:** 18.5+
> **Language:** Swift 6.1 + SwiftUI

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Pattern: MVVM-Coordinator](#2-architecture-pattern-mvvm-coordinator)
3. [App Lifecycle & Initialization](#3-app-lifecycle--initialization)
4. [Navigation Architecture](#4-navigation-architecture)
5. [Services Layer](#5-services-layer)
6. [Screen Modules](#6-screen-modules)
7. [OIDC & Authentication](#7-oidc--authentication)
8. [External Dependencies](#8-external-dependencies)
9. [Build System & Tooling](#9-build-system--tooling)
10. [Testing Infrastructure](#10-testing-infrastructure)
11. [Security Audit Findings](#11-security-audit-findings)
12. [Legacy Issues & Rebranding Gaps](#12-legacy-issues--rebranding-gaps)
13. [Recommendations](#13-recommendations)
14. [Quick Reference](#14-quick-reference)

---

## 1. Project Overview

GIM is a Matrix messaging client forked from Element X iOS, rebranded for the `g.im` domain. It provides end-to-end encrypted messaging, voice/video calls, and full Matrix protocol support via the Matrix Rust SDK.

### 1.1 Targets

| Target | Purpose |
|--------|---------|
| **ElementX** | Main app (`im.g.message`) |
| **NSE** | Notification Service Extension (background push processing) |
| **ShareExtension** | System share sheet integration |
| **SDKMocks** | Shared mock types for Matrix Rust SDK |
| **UnitTests** | Business logic tests |
| **PreviewTests** | SwiftUI snapshot tests (Git LFS) |
| **UITests** | Automation UI tests (device-specific) |
| **AccessibilityTests** | Accessibility compliance tests |
| **IntegrationTests** | End-to-end tests |

### 1.2 Project Structure

```
element-x-ios/
├── ElementX/
│   └── Sources/
│       ├── Application/          # App lifecycle, settings, coordinator
│       │   ├── AppCoordinator.swift    # Root coordinator
│       │   ├── AppDelegate.swift
│       │   └── Settings/
│       │       ├── AppSettings.swift   # 40+ feature flags
│       │       └── OIDCConfiguration.swift
│       ├── FlowCoordinators/     # 22 flow coordinators
│       ├── Screens/              # 56+ screens (MVVM pattern)
│       ├── Services/             # 26 service modules
│       ├── Generated/            # SwiftGen/Sourcery output
│       ├── Mocks/                # Generated mocks
│       ├── Other/                # Utilities, extensions, base classes
│       └── AppHooks/             # Customization hooks (rebranding)
├── NSE/                          # Notification extension
├── ShareExtension/               # Share extension
├── SDKMocks/                     # Rust SDK mock types
├── compound-ios/                 # Design system (local package)
├── Tools/                        # CLI tools (Package.swift)
├── project.yml                   # XcodeGen project definition
├── app.yml                       # App-specific settings
└── fastlane/                     # Build automation
```

---

## 2. Architecture Pattern: MVVM-Coordinator

Every screen follows a strict **5-file pattern**:

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│  *Screen.swift │◄───│  *ViewModel.swift  │◄───│ *Coordinator │
│  (SwiftUI View)│    │  (Business Logic)  │    │  (Navigation)│
└─────────────┘     └──────────────────┘     └─────────────┘
                           │                        │
                    ┌──────┴──────┐          ┌──────┴──────┐
                    │ *Models.swift │          │ CoordinatorAction│
                    │ ViewState     │          │ (emitted upward) │
                    │ ViewAction    │          └─────────────┘
                    │ ViewModelAction│
                    └─────────────┘
```

### 2.1 File Responsibilities

| File | Role |
|------|------|
| `*Models.swift` | `ViewState` (struct), `ViewAction` (enum from View), `ViewModelAction` (enum to Coordinator), `ViewStateBindings` |
| `*ViewModelProtocol.swift` | Protocol enabling mock injection for tests |
| `*ViewModel.swift` | Processes `ViewAction` → updates `ViewState` → emits `ViewModelAction` via `actionsPublisher` |
| `*Screen.swift` | Pure SwiftUI view, receives `context` from ViewModel, sends `ViewAction` |
| `*Coordinator.swift` | Creates ViewModel, subscribes to `actionsPublisher`, emits `CoordinatorAction` for parent |

### 2.2 ViewModel Base Class

```swift
// StateStoreViewModelV2<State, ViewAction>
// Uses @Observable macro for reactive state
// Exposes `context` object to views (views never access ViewModel directly)
```

**Key rule:** Views only interact with `context`, never the ViewModel directly. This enforces unidirectional data flow.

### 2.3 Creating New Screens

```bash
./Tools/Scripts/createScreen.sh FolderName MyScreenName
xcodegen  # Regenerate project
```

---

## 3. App Lifecycle & Initialization

### 3.1 State Machine

AppCoordinator uses SwiftState to manage the app lifecycle:

```
                    ┌──────────────┐
                    │   initial    │
                    └──────┬───────┘
              ┌────────────┼────────────┐
              ▼            ▼            ▼
     ┌────────────┐ ┌───────────┐ ┌──────────┐
     │restoringSession│ │ signedOut │ │softLogout│
     └──────┬─────┘ └─────┬─────┘ └────┬─────┘
            │              │             │
            ▼              ▼             ▼
     ┌─────────────────────────────────────┐
     │            signedIn                  │
     │  (UserSessionFlowCoordinator)        │
     └──────────────┬──────────────────────┘
                    │
                    ▼
             ┌────────────┐
             │  signingOut │
             └────────────┘
```

### 3.2 Initialization Flow

1. `App.init()` → `AppCoordinator` created
2. AppCoordinator checks for existing session in Keychain
3. If session exists → restore session → `signedIn` state
4. If no session → `signedOut` state → show Authentication flow
5. On successful auth → create `UserSessionFlowCoordinator` → `signedIn`

### 3.3 AppSettings (Feature Flags)

`AppSettings.swift` provides 40+ configurable settings:

- User preferences (themes, notifications, timeline)
- Feature flags (threads, public search, key sharing)
- Infrastructure config (push gateway, analytics, Sentry)
- OIDC configuration (redirect URL, client URI)
- Backed by `UserDefaults`, published for SwiftUI reactivity
- Shared with NSE via `CommonSettingsProtocol`

---

## 4. Navigation Architecture

### 4.1 Coordinator Hierarchy

```
AppCoordinator (root)
├── AppLockFlowCoordinator (PIN/biometric overlay)
├── AuthenticationFlowCoordinator (login/registration)
│   ├── AuthenticationStartScreen
│   ├── ServerConfirmationScreen
│   └── OIDCAuthenticationPresenter
├── OnboardingFlowCoordinator (first-run experience)
└── UserSessionFlowCoordinator (main app)
    ├── NavigationTabCoordinator
    │   ├── ChatsTabFlowCoordinator (Chats tab)
    │   │   ├── HomeScreen
    │   │   ├── RoomFlowCoordinator (per-room)
    │   │   │   ├── RoomScreen (timeline)
    │   │   │   ├── RoomDetailsScreen
    │   │   │   ├── RoomMembersFlowCoordinator
    │   │   │   ├── RoomRolesAndPermissionsFlowCoordinator
    │   │   │   ├── MediaEventsTimelineFlowCoordinator
    │   │   │   └── PinnedEventsTimelineFlowCoordinator
    │   │   ├── StartChatFlowCoordinator
    │   │   └── GlobalSearchScreen
    ├── SettingsFlowCoordinator
    │   ├── SettingsScreen
    │   ├── LabsScreen
    │   ├── EncryptionSettingsFlowCoordinator
    │   └── AppLockSetupFlowCoordinator
    ├── BugReportFlowCoordinator
    ├── EncryptionResetFlowCoordinator
    └── LinkNewDeviceFlowCoordinator
```

### 4.2 Navigation Primitives

| Primitive | Purpose |
|-----------|---------|
| `NavigationRootCoordinator` | Root view controller management |
| `NavigationSplitCoordinator` | iPad split view (sidebar + detail) |
| `NavigationStackCoordinator` | SwiftUI NavigationStack wrapper |
| `NavigationTabCoordinator` | Bottom tab bar |

### 4.3 Navigation Patterns

1. **Push** - `NavigationStack` push (most common)
2. **Sheet** - Modal bottom sheet (`setSheetCoordinator`)
3. **Fullscreen Cover** - Full-screen modal (`setFullScreenCoverCoordinator`)
4. **Overlay** - Floating overlay (`setOverlayCoordinator`)
5. **Split Detail** - iPad detail column (`setDetailCoordinator`)
6. **Tab Switch** - Bottom tab bar (`selectedTab`)

### 4.4 State Machines for Complex Flows

`ChatsTabFlowCoordinator` and `RoomFlowCoordinator` use **SwiftState** for deterministic navigation:

```swift
// Example: ChatsTabFlowCoordinatorStateMachine
enum State { case initial, roomList, roomList_detailShown(roomId) }
enum Event { case selectRoom(roomId), deselectRoom, ... }
```

### 4.5 Deep Linking

`AppRoute` enum handles URLs:
- `matrix://` protocol
- `https://matrix.to/` links
- Custom scheme `im.g.message://`
- Parsed by `AppRouteURLParser` → routed through coordinator hierarchy

---

## 5. Services Layer

### 5.1 Service Categories

26 service modules, all **protocol-based** for testability:

#### Core Services
| Service | Purpose | Rust SDK Wrapper? |
|---------|---------|:-:|
| **Client** | Matrix client operations, sync management | Yes |
| **UserSession** | Active session management, combines all services | Yes |
| **Room** | Room operations (join, leave, invite, settings) | Yes |
| **Timeline** | Message timeline, reactions, edits, threads | Yes |
| **Session** | Session storage, restoration from Keychain | No |

#### Authentication & Security
| Service | Purpose | Rust SDK Wrapper? |
|---------|---------|:-:|
| **Authentication** | OIDC flow, homeserver discovery | Yes |
| **AppLock** | PIN code + biometric lock | No |
| **SessionVerification** | Device verification (emoji/QR) | Yes |
| **SecureBackup** | Key backup and recovery | Yes |
| **Keychain** | Secure credential storage | No |

#### Media & Communication
| Service | Purpose | Rust SDK Wrapper? |
|---------|---------|:-:|
| **Media** | Image/file upload/download | Yes |
| **Audio** | Audio recording/playback | No |
| **VoiceMessage** | Voice message record/encode | No |
| **MediaPlayer** | Audio/video playback | No |
| **ElementCall** | Voice/video calls (WebRTC) | Partial |

#### Features
| Service | Purpose | Rust SDK Wrapper? |
|---------|---------|:-:|
| **Notification** | Push notification handling | Yes |
| **NotificationSettings** | Per-room notification config | Yes |
| **Polls** | Poll creation and voting | Yes |
| **Emojis** | Emoji search and categories | No |
| **ComposerDraft** | Message draft persistence | Yes |

#### Infrastructure
| Service | Purpose | Rust SDK Wrapper? |
|---------|---------|:-:|
| **Analytics** | PostHog telemetry | No |
| **BugReport** | Rageshake crash reports | No |
| **LinkMetadata** | URL preview metadata | No |
| **Users** | User profile management | Yes |
| **RoomDirectorySearch** | Public room search | Yes |
| **StateMachine** | SwiftState factory | No |

### 5.2 Service Architecture Notes

- **ClientProxy** (~600 lines) is the largest service, wrapping the Rust SDK client. It's a candidate for decomposition.
- **16 services** directly wrap Rust SDK types; **12** are platform-specific
- All services use `@Automockable` protocol for Sourcery mock generation
- Services are injected via `ServiceLocator` pattern
- **Potentially dead code:** BugReport (rageshake URL is localhost), LinkMetadata (minimal usage)

---

## 6. Screen Modules

### 6.1 Screen Inventory (75+ screens)

| Category | Screens |
|----------|---------|
| **Authentication** | AuthenticationStart, ServerConfirmation, Login |
| **Onboarding** | IdentityConfirmation, IdentityConfirmed, AnalyticsPrompt, NotificationPermissions, AppLockSetup |
| **Home** | HomeScreen, GlobalSearch |
| **Room** | RoomScreen, ThreadTimeline, PinnedEventsTimeline, MediaEventsTimeline |
| **Room Management** | RoomDetails, RoomDetailsEdit, EditRoomAddress, RoomNotificationSettings, SecurityAndPrivacy, RoomChangePermissions, RoomChangeRoles, RoomRolesAndPermissions, KnockRequestsList |
| **Members** | RoomMemberList, RoomMemberDetails, ManageRoomMemberSheet, InviteUsers |
| **Messages** | MessageForwarding, ReportContent, ReportRoom, DeclineAndBlock, ResolveVerifiedUserSendFailure |
| **Media** | MediaPicker, MediaUploadPreview, FilePreview, LocationSharing |
| **Settings** | Settings, Labs, LinkNewDevice, LogViewer |
| **Security** | SecureBackup (RecoveryKey, KeyBackup), EncryptionReset, QRCodeLogin |
| **App Lock** | AppLockScreen, AppLockSetup |
| **Calls** | CallScreen |
| **Polls** | CreatePoll, RoomPollsHistory |
| **Users** | UserProfile, StartChat, CreateRoom, RoomSelection |
| **Other** | EmojiPicker, BugReport, BlockedUsers, JoinRoom |

---

## 7. OIDC & Authentication

### 7.1 Authentication Flow

```
User taps "Continue" on Start Screen
         │
         ▼
AuthenticationService.configure(homeserverAddress)
         │
         ├── Discovers .well-known
         ├── Detects OIDC support
         └── Returns server login mode
         │
         ▼
OIDCAuthenticationPresenter
         │
         ├── Builds OIDCConfiguration
         │   ├── redirectURL: im.g.message://oidc/callback
         │   ├── clientURI: https://g.im
         │   └── PKCE: S256 with 128-byte verifier
         │
         ├── Rust SDK initiates dynamic client registration
         │   └── Server returns client_id: 'matrix'
         │
         └── Opens ASWebAuthenticationSession (ephemeral)
              │
              ▼
         User authenticates (upstream OIDC provider)
              │
              ▼
         Redirect: im.g.message://oidc/callback?code=...&state=...
              │
              ▼
         Rust SDK exchanges code for tokens (PKCE verified)
              │
              ▼
         Session established → stored in Keychain
```

### 7.2 Token Storage

```
Keychain [RestorationToken]
  ├── session.accessToken     (Bearer token)
  ├── session.refreshToken    (OIDC only)
  ├── session.oidcData        (Provider metadata)
  ├── passphrase              (256-bit key for SQLite encryption)
  └── sessionDirectories      (Paths to encrypted databases)
```

### 7.3 Security Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| PKCE (S256) | Secure | 128-byte random verifier |
| Token storage | Secure | iOS Keychain with OS-level encryption |
| Web session | Secure | Ephemeral (no cookies persisted) |
| Custom URL scheme | Secure | `im.g.message://` prevents redirect attacks |
| Certificate pinning | Missing | No HTTPS pinning implemented |
| Keychain accessibility | Default | Should use `kSecAttrAccessibleAfterFirstUnlock` |
| Passphrase in Keychain | Risk | Stored as plaintext JSON in RestorationToken |

---

## 8. External Dependencies

### 8.1 Dependency Summary

**34 total packages:** 28 external SPM + 5 Element-hosted + 1 local

### 8.2 Essential Dependencies

| Package | Version | Purpose | Imports |
|---------|---------|---------|:-------:|
| **MatrixRustSDK** | v26.02.13 | Core Matrix protocol, E2EE, sync | 150+ |
| **Compound** | local | Design system (colors, tokens, components) | 191 |
| **WysiwygComposer** | v2.41.0 | Rich text message editor | ~20 |
| **EmbeddedElementCall** | v0.16.3 | WebRTC calling integration | ~10 |
| **KeychainAccess** | - | Secure token storage | 34 |
| **Kingfisher** | - | Image caching/loading | ~30 |
| **SwiftState** | - | State machines for navigation | 19 |

### 8.3 Potentially Removable

| Package | Reason |
|---------|--------|
| **Dynamic** (v1.2) | **0 imports found** - unused |
| **LoremSwiftum** (v2.2.3) | Dev-only (1 usage in mocks) |
| **KZFileWatchers** (v1.2.0) | Dev-only (UI test signaling) |
| **DeviceKit** (v5.7.0) | Could use native `UIDevice` APIs |
| **Version** (v2.2.0) | Could migrate to native iOS version comparison |

### 8.4 Migration Opportunities

| Current | Alternative |
|---------|-------------|
| GZIP | `Foundation.Compression` |
| SwiftUI-Introspect | `@FocusState` + native APIs |
| DeviceKit | `UIDevice` + `ProcessInfo` |

---

## 9. Build System & Tooling

### 9.1 XcodeGen

- All project configuration in YAML (`project.yml`, `app.yml`, `target.yml`)
- **Never** edit `ElementX.xcodeproj` directly
- Run `xcodegen` after any YAML changes

### 9.2 Code Generation Pipeline

```
Build Phase Order:
1. SwiftGen     → Type-safe strings & assets (Generated/)
2. Sourcery     → Protocol mocks (@Automockable)
3. SwiftLint    → Code quality enforcement
4. SwiftFormat  → Code formatting
5. Git Version  → Embed commit hash
```

### 9.3 Key Build Commands

```bash
# Setup project
swift run tools setup-project

# Regenerate project
xcodegen

# Build Rust SDK locally
swift run tools build-sdk

# Format code
swiftformat .

# Run unit tests
bundle exec fastlane unit_tests

# Run UI tests
bundle exec fastlane ui_tests device:iPhone
```

### 9.4 Versioning

- **Calendar-based**: `YY.MM.PATCH` (e.g., 26.02.0)
- Git tag triggers release pipeline

### 9.5 Code Quality Enforcement

**SwiftLint rules (errors, not warnings):**
- Use `MXLog` instead of `print()`
- Use `ElementNavigationStack` instead of `NavigationStack`
- Specify explicit `spacing:` on `VStack`/`HStack`
- Max function body: 100 lines
- Max 10 parameters per function

### 9.6 Variants

| Variant | Bundle ID | Purpose |
|---------|-----------|---------|
| Default | `im.g.message` | Production |
| Nightly | `io.element.elementx.nightly` | Nightly builds (needs rebranding) |

---

## 10. Testing Infrastructure

### 10.1 Test Targets

| Target | Type | Run Command |
|--------|------|-------------|
| UnitTests | XCTest | `bundle exec fastlane unit_tests` |
| PreviewTests | Snapshot (Git LFS) | `bundle exec fastlane unit_tests` |
| UITests | UI Automation | `bundle exec fastlane ui_tests device:iPhone` |
| AccessibilityTests | A11y Compliance | `bundle exec fastlane accessibility_tests` |
| IntegrationTests | E2E | `bundle exec fastlane integration_tests` |

### 10.2 Mock Generation

- Sourcery auto-generates mocks from `@Automockable` protocols
- SDKMocks target provides Rust SDK mock types
- All services have corresponding mock implementations

### 10.3 Snapshot Tests

- Use SnapshotTesting library
- Stored in `Sources/__Snapshots__/` within each test target
- Managed with Git LFS

---

## 11. Security Audit Findings

### 11.1 CRITICAL Issues

| # | Issue | File | Impact |
|---|-------|------|--------|
| 1 | **Element PostHog/Sentry hardcoded** | `AppSettings.swift:371-373` | User analytics sent to Element's servers |
| 2 | **Associated domains reference element.io** | `target.yml:108-117` | Deep links from Element domains accepted |
| 3 | **Sentry crash reports to Element** | `Secrets.swift`, `fastlane/Fastfile:174` | Crash data sent to Element infrastructure |
| 4 | **PostHog analytics to Element** | `Secrets.swift:4-5` | User behavior tracked by Element |

**Details:**

```swift
// AppSettings.swift:371-373 - HARDCODED Element Call telemetry
elementCallPosthogAPIHost = "https://posthog-element-call.element.io"
elementCallPosthogAPIKey = "phc_rXGHx9vDmyEvyRxPziYtdVIv0ahEv8A9uLWFcCi1WcU"
elementCallPosthogSentryDSN = "https://3bd2f95ba5554d4497da7153b552ffb5@sentry.tools.element.io/41"
```

```yaml
# target.yml:108-117 - SHOULD BE g.im DOMAINS
com.apple.developer.associated-domains:
  - applinks:element.io
  - applinks:app.element.io
  - webcredentials:*.element.io  # ALLOWS ELEMENT PASSWORD AUTOFILL
```

### 11.2 HIGH Priority Issues

| # | Issue | File | Impact |
|---|-------|------|--------|
| 5 | Element Pro App Store link hardcoded | `AppSettings.swift:233` | Forks users to Element's app |
| 6 | `io.element.call` URL scheme still active | `Info.plist:47` | URL scheme hijacking risk |
| 7 | `bugReportApplicationID = "element-x-ios"` | `AppSettings.swift:315` | Bug reports identify as Element |
| 8 | Element bundle IDs in Nightly variant | `Variants/Nightly/nightly.yml` | Nightly uses `io.element.elementx.nightly` |

### 11.3 MEDIUM Priority Issues

| # | Issue | File |
|---|-------|------|
| 9 | `call.element.io` in known hosts | `AppRoutes.swift:138` |
| 10 | Rageshake URL placeholder | `Secrets.swift:6` |
| 11 | Analytics terms URL → element.io | `AppSettings.swift:322` |
| 12 | Element web hosts hardcoded | `AppSettings.swift:228` |
| 13 | `mobile.element.io` account provisioning | `AppSettings.swift:230` |
| 14 | No certificate pinning | All HTTPS communication |
| 15 | Keychain accessibility not hardened | Default accessibility level |

### 11.4 LOW Priority Issues

| # | Issue | File |
|---|-------|------|
| 16 | README references Element | `README.md` |
| 17 | SECURITY.md → security@element.io | `SECURITY.md:3` |
| 18 | LICENSE-COMMERCIAL → licensing@element.io | `LICENSE-COMMERCIAL:6` |
| 19 | Test data contains element.io URLs | Multiple test files |

### 11.5 Positive Security Notes

- App Transport Security enforced (no arbitrary loads)
- iOS Keychain for token storage
- File protection `.complete` on sensitive caches
- App sandbox enabled
- Properly scoped entitlements
- PKCE S256 with cryptographic random
- No hardcoded passwords (externalized to Secrets.swift)

---

## 12. Legacy Issues & Rebranding Gaps

### 12.1 URLs Still Pointing to Element

| URL | Location | Should Be |
|-----|----------|-----------|
| `posthog-element-call.element.io` | AppSettings.swift:371 | Self-hosted or disabled |
| `sentry.tools.element.io` | AppSettings.swift:373, fastlane | Self-hosted or disabled |
| `app.element.io` | AppSettings.swift:228, target.yml | `g.im` |
| `mobile.element.io` | AppSettings.swift:230 | `g.im` equivalent |
| `element.io/cookie-policy` | AppSettings.swift:322 | `g.im` privacy policy |
| `call.element.io` | AppRoutes.swift:138 | Self-hosted call server |
| `element.io` (3 instances) | RoomScreenFooterView.swift:162-167 | `g.im` |

### 12.2 Remaining Element Branding

| Item | Location | Action Needed |
|------|----------|---------------|
| App Store link (Element Pro) | AppSettings.swift:233 | Remove or replace |
| Bug report app ID | AppSettings.swift:315 | Change to "gim" |
| io.element.call scheme | Info.plist | Remove |
| Nightly bundle ID | nightly.yml | Change to `im.g.message.nightly` |
| Associated domains | target.yml | Replace with g.im domains |
| webcredentials | target.yml | Remove element.io wildcard |

### 12.3 Potentially Dead Code

| Module | Evidence | Recommendation |
|--------|----------|----------------|
| BugReport service | Rageshake URL is localhost | Remove or configure for g.im |
| LinkMetadata service | Minimal usage | Evaluate necessity |
| Dynamic package | 0 imports | Remove from dependencies |

### 12.4 Code Quality Concerns

| Issue | Location | Impact |
|-------|----------|--------|
| ClientProxy too large | ~600 lines | Decompose into focused modules |
| Timeline service oversized | ~400 lines | Split timeline concerns |
| JoinedRoomProxy oversized | ~500 lines | Extract sub-protocols |

---

## 13. Recommendations

### 13.1 MUST DO (Before Production)

1. **Remove all Element infrastructure endpoints** from production code
   - Update PostHog host/key to self-hosted or disable
   - Update Sentry DSNs to self-hosted or disable
   - Change rageshake URL to GIM server
   - Remove Element Pro App Store link

2. **Update Associated Domains**
   - Remove all `element.io` entries
   - Add `g.im` domains
   - Remove `webcredentials:*.element.io`

3. **Fix identification**
   - `bugReportApplicationID` → `"gim"`
   - Nightly variant bundle ID → `im.g.message.nightly`

4. **Remove `io.element.call` URL scheme**

5. **Create privacy policy** at `g.im` domain

### 13.2 SHOULD DO (Security Hardening)

6. Implement certificate pinning for g.im homeserver
7. Harden Keychain accessibility to `kSecAttrAccessibleAfterFirstUnlock`
8. Add PostHog/Sentry kill switch (feature flags exist but verify)
9. Audit and update all hardcoded URLs
10. Review Element Call integration for g.im compatibility

### 13.3 NICE TO HAVE (Code Quality)

11. Remove `Dynamic` package (unused)
12. Decompose `ClientProxy` into focused services
13. Exclude `LoremSwiftum`/`KZFileWatchers` from production builds
14. Update README, SECURITY.md, LICENSE-COMMERCIAL
15. Clean up test data referencing element.io
16. Evaluate DeviceKit → native APIs migration

---

## 14. Quick Reference

### 14.1 Key Files

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen project definition |
| `app.yml` | Bundle ID, team, entitlements |
| `ElementX/SupportingFiles/target.yml` | Target-specific settings, URL schemes |
| `AppCoordinator.swift` | Root coordinator, app lifecycle |
| `AppSettings.swift` | Feature flags, configuration |
| `OIDCConfiguration.swift` | OIDC redirect URL, client URI |
| `Secrets.swift` | API keys, DSNs (externalized) |
| `StateStoreViewModelV2.swift` | ViewModel base class |

### 14.2 Common Commands

```bash
# First-time setup
swift run tools setup-project

# After changing YAML configs
xcodegen

# Format code
swiftformat .

# Run tests
bundle exec fastlane unit_tests
bundle exec fastlane ui_tests device:iPhone

# Create new screen
./Tools/Scripts/createScreen.sh FolderName ScreenName && xcodegen
```

### 14.3 Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                        App Layer                         │
│  AppCoordinator → FlowCoordinators → Screen Coordinators│
├─────────────────────────────────────────────────────────┤
│                      View Layer                          │
│  SwiftUI Screens ←── context ←── ViewModels             │
├─────────────────────────────────────────────────────────┤
│                    Services Layer                        │
│  27 Protocol-Based Services (protocol → mock/real impl) │
├─────────────────────────────────────────────────────────┤
│                   Rust SDK Layer                         │
│  MatrixRustSDK (E2EE, Sync, Timeline, Rooms, Users)    │
├─────────────────────────────────────────────────────────┤
│                  Platform Layer                          │
│  iOS Keychain, FileManager, URLSession, WebRTC          │
└─────────────────────────────────────────────────────────┘
```

### 14.4 Data Flow

```
User Action → View → ViewAction → ViewModel → ViewModelAction → Coordinator
                                      │                              │
                                      ▼                              ▼
                               Service Layer                  CoordinatorAction
                                      │                              │
                                      ▼                              ▼
                              Matrix Rust SDK              Parent Coordinator
                                      │                     (navigation decision)
                                      ▼
                               Matrix Server
```

---

## Appendix A: Dependency Matrix

| Package | Main App | NSE | Share | Tests |
|---------|:--------:|:---:|:-----:|:-----:|
| MatrixRustSDK | x | x | x | x |
| Compound | x | x | x | |
| KeychainAccess | x | x | x | |
| Kingfisher | x | x | | |
| Collections | x | x | x | |
| SwiftState | x | | | |
| WysiwygComposer | x | | | |
| EmbeddedElementCall | x | | | |
| PostHog | x | | | |
| Sentry | x | | | |
| SnapshotTesting | | | | x |
| MapLibre | x | | | |

## Appendix B: Security Issue Tracker

| ID | Severity | Issue | Status |
|----|----------|-------|--------|
| SEC-01 | CRITICAL | PostHog/Sentry to Element servers | Unfixed |
| SEC-02 | CRITICAL | Associated domains → element.io | Unfixed |
| SEC-03 | CRITICAL | Crash reports to Element | Unfixed |
| SEC-04 | CRITICAL | Analytics to Element | Unfixed |
| SEC-05 | HIGH | Element Pro App Store link | Unfixed |
| SEC-06 | HIGH | io.element.call scheme active | Unfixed |
| SEC-07 | HIGH | Bug report ID = "element-x-ios" | Unfixed |
| SEC-08 | HIGH | Nightly bundle ID = io.element | Unfixed |
| SEC-09 | MEDIUM | call.element.io known host | Unfixed |
| SEC-10 | MEDIUM | No certificate pinning | Unfixed |
| SEC-11 | MEDIUM | Keychain accessibility default | Unfixed |
| SEC-12 | MEDIUM | Analytics terms → element.io | Unfixed |
| SEC-13 | LOW | Documentation references Element | Unfixed |

---

*Generated by GIM Architecture Audit Team - 2026-02-20*
