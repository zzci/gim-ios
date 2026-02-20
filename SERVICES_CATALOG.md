# GIM Services Catalog

A comprehensive analysis of all 28 services in the Element X iOS codebase, including their purpose, responsibilities, dependencies, and usage patterns.

**Analyzed Date:** February 2026
**Repository:** GIM (Element X iOS Fork) at `/app/ai/matrix/element-x-ios`

---

## Overview

The services layer is organized around the MVVM-Coordinator architecture. Services are protocol-based, testable, and injected into ViewModels. Most services wrap or delegate to the Matrix Rust SDK, providing a platform-specific interface.

### Service Categories

1. **Authentication & Sessions** - User login, OIDC, session management
2. **Client & Room Management** - Matrix client operations, room proxies
3. **Timeline & Messages** - Message handling, threading, editing
4. **User & Room Data** - Member info, profiles, discovery
5. **Security & Verification** - E2E encryption, key backup, device verification
6. **Media & Files** - Media loading, uploading, conversion
7. **Notifications** - Push notifications, notification settings
8. **Communication Features** - Voice messages, audio/video calls, polls
9. **UI Support** - Analytics, app lock, emojis, composers
10. **Utilities** - State machines, keychain, bug reports

---

## Service Detailed Analysis

### 1. **Analytics Service**

**Purpose:** Event tracking and telemetry for user behavior and app performance

**Key Files:**
- `AnalyticsClientProtocol.swift` - Interface for analytics clients
- `AnalyticsService.swift` - Main service managing analytics state and events
- `PostHogAnalyticsClient.swift` - PostHog implementation
- `Signposter.swift` - Performance profiling
- `UserPropertiesExt.swift` - User property helpers

**Key Types:**
- `AnalyticsService` - Main service class
- `AnalyticsClientProtocol` - Abstract analytics client interface
- `Signposter` - Performance monitoring

**Responsibilities:**
- Manage analytics opt-in/opt-out consent
- Route analytics events to PostHog or other clients
- Track screens, interactions, errors, room events
- Monitor session security state changes
- Update user properties for segmentation

**Dependencies:**
- `AppSettings` - Configuration and consent state
- `AnalyticsEvents` package - Shared event schemas
- `PostHog` framework - Analytics backend

**Notable Patterns:**
- Uses shared event definitions from matrix-analytics-events repo
- Separate signpost client for performance metrics (not affected by opt-in state)
- Context-aware error tracking (UTD, cryptography, federation)
- Integrates room moderation actions and poll events

**Active:** Yes - Core feature for metrics collection

---

### 2. **AppLock Service**

**Purpose:** Device unlock protection using PIN codes and biometric authentication

**Key Files:**
- `AppLockServiceProtocol.swift` - Service interface
- `AppLockService.swift` - PIN/biometric management
- `AppLockTimer.swift` - Grace period and lock timeout
- `LAContextMock.swift` - Mock for testing

**Key Types:**
- `AppLockService` - Main service
- `AppLockServiceError` - Error types (invalid PIN, keychain errors)
- `AppLockServiceBiometricResult` - Biometric unlock results

**Responsibilities:**
- Validate PIN codes (4 digits, not weak patterns)
- Enable/disable biometric unlock (Face/Touch ID)
- Track failed PIN attempts
- Manage app lock grace period
- Monitor biometric state changes for invalidation

**Dependencies:**
- `KeychainController` - PIN storage and state
- `AppSettings` - App lock settings and grace period
- `LocalAuthentication` (LAContext) - System biometrics
- `AppLockTimer` - Timeout management

**Notable Patterns:**
- Main actor (thread-safe)
- Biometric trust verification via policy domain state
- Auto-fixes stale biometric state on successful PIN unlock
- Mandatory app lock option for compliance

**Active:** Yes - Security feature for locked devices

---

### 3. **Audio Service**

**Purpose:** Audio recording, playback, and format conversion (Opus/M4A)

**Key Files:**
- `AudioConverter.swift` - Format conversion
- `AudioConverterProtocol.swift` - Converter interface
- `AudioSessionProtocol.swift` - Audio session management
- `Player/` - Audio playback components
- `Recorder/` - Recording components
- **Total: ~1,298 lines**

**Key Types:**
- `AudioConverter` - Converts between Opus OGG and MPEG4 AAC
- `AudioConverterError` - Conversion errors
- Audio player/recorder (details in subdirectories)

**Responsibilities:**
- Record audio in M4A format
- Convert between Opus OGG and MPEG4 AAC
- Manage audio session (recording/playback modes)
- Handle audio focus and interruptions

**Dependencies:**
- `AVFoundation` - Core audio framework
- `SwiftOGG` - OGG conversion library
- Custom Player/Recorder implementations

**Notable Patterns:**
- Uses SwiftOGG for format conversion
- Separate audio session management
- Protocol-based for testability

**Active:** Yes - Used for voice messages

---

### 4. **Authentication Service**

**Purpose:** Handle user authentication flows (OIDC, password, QR code login)

**Key Files:**
- `AuthenticationServiceProtocol.swift` - Main interface
- `AuthenticationService.swift` - Implementation
- `AuthenticationClientFactory.swift` - Client creation
- `LinkNewDeviceService.swift` - Device linking

**Key Types:**
- `AuthenticationService` - Main service
- `AuthenticationFlow` - Login vs register flow
- `AuthenticationServiceError` - 13+ error types
- `OIDCAuthorizationDataProxy` - OIDC auth data
- `QRLoginProgress` - QR code login state machine
- `OIDCError`, `QRCodeLoginError` - Specific error enums

**Responsibilities:**
- Configure client for a homeserver
- Implement OIDC login flow
- Implement password-based login
- Implement QR code device linking login
- Create user sessions on successful login
- Validate homeserver capabilities (OIDC, password login, sliding sync)

**Dependencies:**
- `ClientFactory` - Rust SDK client creation
- `UserSessionStore` - Session persistence
- `EncryptionKeyProvider` - Passphrase generation
- `AppSettings` - Account provider defaults
- `AppHooks` - Lifecycle hooks
- Matrix Rust SDK types (Client, LoginHomeserver, etc.)

**Notable Patterns:**
- Async/await throughout
- Result types for error handling
- Wraps Rust SDK errors in native error enum
- Supports multiple login modes (OIDC primary, password fallback, QR code)
- Creates fully configured UserSession on success

**Active:** Yes - Core authentication flow

---

### 5. **BugReport Service**

**Purpose:** Collect and submit bug reports with device info and logs

**Key Files:**
- `BugReportServiceProtocol.swift` - Service interface
- `BugReportService.swift` - Implementation

**Key Types:**
- `BugReport` - Report data structure
- `BugReportServiceError` - Upload failures
- `SubmitBugReportResponse` - Server response

**Responsibilities:**
- Submit bug reports to bug tracker
- Include device info (userID, deviceID, crypto keys)
- Attach log files
- Track crash events
- Monitor upload progress

**Dependencies:**
- URLSession - HTTP uploads
- External bug tracker endpoint

**Notable Patterns:**
- Progress tracking via CurrentValueSubject
- Optional file attachments
- Github labels for categorization

**Active:** Yes - If enabled in build configuration

---

### 6. **Client Service (ClientProxy)**

**Purpose:** Main interface to the Matrix Rust SDK for all client operations

**Key Files:**
- `ClientProxyProtocol.swift` - Service interface (~100+ methods)
- `ClientProxy.swift` - Full implementation (~600+ lines)
- `Client.swift` - Thin wrapper

**Key Types:**
- `ClientProxy` - Main proxy to Rust SDK
- `ClientProxyAction` - Sync, auth errors, decryption errors
- `ClientProxyLoadingState` - Loading/not loading
- `ClientProxyError` - 7+ error types
- `CreateRoomAccessType` - Room access configurations
- `SessionVerificationState` - User verification state
- `PusherConfiguration` - Push notification setup

**Responsibilities:**
- Manage room list (sliding sync)
- Sync with homeserver
- Create/join rooms
- Upload/download media
- Handle verification state
- Monitor notification settings
- Manage spaces
- Send queue status
- Load and cache user data
- Decrypt timeline events

**Dependencies:**
- Matrix Rust SDK (Client, RoomListService, SyncService)
- `NetworkMonitor` - Connection monitoring
- `AppSettings` - Configuration
- `AnalyticsService` - Error tracking
- `MediaLoader` - Media handling
- `RoomSummaryProvider` - Room list filtering
- `NotificationSettings` - Notification rules
- `SecureBackupController` - E2E backup
- `SessionVerificationController` - Device verification
- `SpaceService` - Space management

**Notable Patterns:**
- Large class (600+ lines) - may need refactoring
- Holds multiple task handles for async listeners
- Manages multiple room summary providers
- Complex power level configuration for room creation
- Reactive publishers for state changes
- Error handling for soft/hard logout

**Active:** Yes - Core service, essential

**Potential Issues:**
- Large monolithic class
- Many dependencies (tight coupling)
- Multiple state synchronization concerns

---

### 7. **ComposerDraft Service**

**Purpose:** Persist and restore message composer drafts

**Key Files:**
- `ComposerDraftServiceProtocol.swift` - Service interface
- `ComposerDraftService.swift` - Implementation

**Key Types:**
- `ComposerDraftProxy` - Draft data with type
- `ComposerDraftType` - NewMessage/Reply/Edit variants
- `ComposerDraftServiceError` - Load/save/clear errors

**Responsibilities:**
- Save message drafts (persistent and volatile)
- Load drafts on screen open
- Clear drafts on send
- Load reply context
- Support edit and reply drafts

**Dependencies:**
- Rust SDK timeline controller
- Timeline for reply context lookup

**Notable Patterns:**
- Dual persistence: persistent (database) and volatile (memory)
- Separate reply loading logic
- Wraps Rust SDK draft types

**Active:** Yes - Core composer feature

---

### 8. **ElementCall Service**

**Purpose:** Manage audio/video calls using Element Call (WebRTC)

**Key Files:**
- `ElementCallServiceProtocol.swift` - Service interface
- `ElementCallService.swift` - Implementation (~500+ lines)
- `ElementCallWidgetDriver.swift` - Widget management
- `GenericCallLinkWidgetDriver.swift` - Generic call links
- `ElementCallConfiguration.swift` - Call configuration
- `CXProviderProtocol.swift` - Call kit provider
- **Total: ~869 lines**

**Key Types:**
- `ElementCallService` - Main service
- `ElementCallServiceAction` - Call state changes
- `ElementCallConfiguration` - Configuration
- `ElementCallWidgetDriver` - WebRTC widget control
- `GenericCallLinkWidgetDriver` - Generic call link support

**Responsibilities:**
- Setup/teardown call sessions
- Manage call state transitions
- Control audio/video
- Handle incoming call requests
- Integrate with CallKit (system phone app)
- Bridge to WebRTC widget
- Support both room calls and generic call links

**Dependencies:**
- `ClientProxy` - Room and event access
- Native CallKit framework
- WebRTC widget (separate framework/binary)

**Notable Patterns:**
- State machine for call lifecycle
- Audio enable/disable control
- Integration with system call handling
- Widget-based implementation (separates WebRTC complexity)

**Active:** Yes - Core calling feature

---

### 9. **Emojis Service**

**Purpose:** Provide emoji categories and search functionality

**Key Files:**
- `EmojiProviderProtocol.swift` - Service interface
- `EmojiProvider.swift` - Implementation
- `EmojiLoaderProtocol.swift` - Data loading

**Key Types:**
- `EmojiProvider` - Main provider
- `EmojiItem` - Individual emoji with metadata
- `EmojiCategory` - Grouped emojis
- `EmojiProviderState` - Loading state machine

**Responsibilities:**
- Load emoji categories from built-in data
- Search emojis by keywords/shortcodes
- Track frequently used emojis
- Manage loading state

**Dependencies:**
- Built-in emoji database
- UserDefaults for frequently used tracking

**Notable Patterns:**
- Main actor annotation
- Async loading with state machine
- Task-based deduplication of concurrent loads

**Active:** Yes - Emoji picker feature

---

### 10. **Keychain Service**

**Purpose:** Secure storage of credentials and app lock settings

**Key Files:**
- `KeychainControllerProtocol.swift` - Service interface
- `KeychainController.swift` - Implementation
- `KeychainControllerMock.swift` - Test mock

**Key Types:**
- `KeychainController` - Main keychain manager
- `KeychainCredentials` - User/token pair
- `KeychainControllerProtocol` - Abstract interface

**Responsibilities:**
- Store/retrieve restoration tokens for session resumption
- Store/retrieve PIN codes for app lock
- Store/retrieve biometric state
- Implement ClientSessionDelegate (SDK callbacks)

**Dependencies:**
- Security.framework - Keychain access
- Matrix Rust SDK (ClientSessionDelegate)

**Notable Patterns:**
- Implements SDK delegate for automatic token refresh
- Secured keychain access groups
- Biometric state tracked separately from PIN

**Active:** Yes - Core security feature

---

### 11. **LinkMetadata Service**

**Purpose:** Fetch and cache link preview metadata (title, image, description)

**Key Files:**
- `LinkMetadataProviderProtocol.swift` - Service interface
- `LinkMetadataProvider.swift` - Implementation

**Key Types:**
- `LinkMetadataProvider` - Main provider
- `LinkMetadataProviderItem` - Cached metadata

**Responsibilities:**
- Fetch metadata for URLs
- Cache results
- Parse OpenGraph/HTML metadata

**Dependencies:**
- LinkPresentation framework (Apple)

**Notable Patterns:**
- In-memory caching
- URL-keyed dictionary for quick lookup

**Active:** Yes - Message link previews

---

### 12. **Media Service**

**Purpose:** Handle media uploads and preprocessing (image scaling, compression)

**Key Files:**
- `MediaUploadingPreprocessor.swift` - Image/video preprocessing
- `Provider/` subdirectory containing media loading
  - `MediaProvider.swift` - Media download and caching
  - `MediaProviderProtocol.swift` - Interface
  - `MediaLoader.swift` - HTTP media loading
  - `MediaLoaderProtocol.swift` - Interface

**Key Types:**
- `MediaProvider` - Main media access service
- `MediaLoader` - Downloads media from URLs
- `MediaUploadingPreprocessor` - Prepares media for upload

**Responsibilities:**
- Download and cache media (images, files, videos)
- Generate thumbnails
- Preprocess uploads (scale images, compress)
- Load media with retry logic
- Manage media cache

**Dependencies:**
- Rust SDK media client
- URLSession - Network media loading
- ImageIO - Image processing

**Notable Patterns:**
- Separate loading and caching layers
- Retry on network reconnection
- Image scaling for preview/thumbnail
- File handle proxies for memory-efficient access

**Active:** Yes - Core media handling

---

### 13. **MediaPlayer Service**

**Purpose:** Manage playback state across multiple audio players

**Key Files:**
- `MediaPlayerProviderProtocol.swift` - Service interface
- `MediaPlayerProvider.swift` - Implementation

**Key Types:**
- `MediaPlayerProvider` - State coordinator
- `AudioPlayerState` - Playback state (identified)
- `AudioPlayerProtocol` - Actual player

**Responsibilities:**
- Register/unregister audio player states
- Maintain single active player (detach others)
- Query player state by identifier
- Coordinate playback focus

**Dependencies:**
- Multiple `AudioPlayerState` instances
- `AudioPlayerProtocol` - Actual playback

**Notable Patterns:**
- Main actor for thread safety
- State tracking by identifier
- Detach-others pattern to prevent multiple playback

**Active:** Yes - Audio/voice message playback

---

### 14. **Notification Service**

**Purpose:** Handle push notifications and in-app notification display

**Key Files:**
- `Manager/NotificationManager.swift` - Main notification handler
- `Manager/NotificationManagerProtocol.swift` - Service interface
- `Manager/UserNotificationCenterProtocol.swift` - UNUserNotificationCenter wrapper
- `Manager/APNSPayload.swift` - Payload parsing

**Key Types:**
- `NotificationManager` - Main manager
- `NotificationManagerProtocol` - Abstract interface
- `APNSPayload` - Push notification payload

**Responsibilities:**
- Register for push notifications
- Handle notification tap/interactions
- Process in-app notification display
- Route notifications to correct session
- Handle inline reply
- Decrypt encrypted notifications (NSE)
- Remove delivered notifications for read rooms

**Dependencies:**
- UserNotifications framework (UNUserNotificationCenter)
- `UserSessionProtocol` - Session handling
- NSE extension communication

**Notable Patterns:**
- Delegate pattern for lifecycle events
- Room-based notification management
- Inline reply support
- Coordination with Notification Service Extension

**Active:** Yes - Core push notification feature

---

### 15. **NotificationSettings Service**

**Purpose:** Manage per-room and global notification preferences

**Key Files:**
- `NotificationSettingsProxyProtocol.swift` - Service interface
- `NotificationSettingsProxy.swift` - Implementation
- `RoomNotificationSettingsProxyProtocol.swift` - Room settings interface
- `RoomNotificationSettingsProxy.swift` - Room settings impl
- `RoomNotificationModeProxy.swift` - Notification mode enum
- `NotificationSettingsChatType.swift` - Chat type variants

**Key Types:**
- `NotificationSettingsProxy` - Global settings
- `RoomNotificationSettingsProxy` - Per-room settings
- `RoomNotificationModeProxy` - Mute/notify/loud modes
- `NotificationSettingsChatType` - 1:1/group chat types

**Responsibilities:**
- Get/set per-room notification modes
- Get/set global notification defaults
- Toggle room mentions, calls, invites
- Determine encryption and oneToOne room properties
- Check device notification capability

**Dependencies:**
- Rust SDK notification settings controller
- Room info (encryption state, members)

**Notable Patterns:**
- Callbacks for settings changes
- Async methods throughout
- Distinction between user-defined and default rules

**Active:** Yes - Notification preferences

---

### 16. **Polls Service**

**Purpose:** Handle poll voting and management

**Key Files:**
- `PollInteractionHandlerProtocol.swift` - Service interface
- `PollInteractionHandler.swift` - Implementation

**Key Types:**
- `PollInteractionHandler` - Poll operations

**Responsibilities:**
- Send poll response (vote)
- End poll (admin action)

**Dependencies:**
- Timeline or room controller

**Notable Patterns:**
- Simple, minimal service
- Wraps timeline message sending

**Active:** Yes - Poll voting feature

---

### 17. **Room Service**

**Purpose:** Wrap Rust SDK room types and provide room-specific operations

**Key Files:**
- `RoomProxyProtocol.swift` - Core interface
- `JoinedRoomProxy.swift` - Joined room implementation (~500+ lines)
- `InvitedRoomProxy.swift` - Invited room state
- `KnockedRoomProxy.swift` - Knocked (ask-to-join) state
- `BannedRoomProxy.swift` - Banned room state
- `Room.swift` - Lightweight wrapper
- `RoomInfoProxy.swift` - Room metadata
- `RoomMember/` - Member types
- `RoomMembershipDetails/` - Membership state
- `RoomPreview/` - Preview types
- `RoomSummary/` - Summary for room lists
- Multiple specialized types (JoinRule, RoomRole, RoomPermissions, etc.)

**Key Types:**
- `RoomProxyProtocol` - Abstract room interface
- `RoomProxyType` - Enum of room states (joined/invited/knocked/banned/left)
- `JoinedRoomProxyProtocol` - Full room interface
- `RoomInfoProxy` - Room state (name, topic, avatar, members)
- `RoomSummary` - List item summary
- `RoomPermissions` - User permissions in room
- `RoomRole` - User role (owner/admin/moderator/member)
- `JoinRule` - Public/knock/private/private_knock

**Responsibilities:**
- Provide access to room metadata and state
- Handle room join/invite/knock/ban flows
- Manage room members and permissions
- Provide timeline access
- Handle power level changes
- Create/edit room state events
- Manage room avatars

**Dependencies:**
- Rust SDK Room types
- `TimelineProxy` - Message access

**Notable Patterns:**
- Proxy pattern wrapping Rust SDK
- Enum-based room state (joined/invited/etc)
- Multiple protocol layers for different states
- Power level mappings

**Active:** Yes - Core room management

---

### 18. **RoomDirectorySearch Service**

**Purpose:** Search public room directories on the homeserver

**Key Files:**
- `RoomDirectorySearchProxyProtocol.swift` - Service interface
- `RoomDirectorySearchProxy.swift` - Implementation

**Key Types:**
- `RoomDirectorySearchProxy` - Search service
- `RoomDirectorySearchResult` - Result item
- `RoomDirectorySearchError` - Error types

**Responsibilities:**
- Search room directory
- Paginate results
- Provide reactive results publisher

**Dependencies:**
- Rust SDK room directory client

**Notable Patterns:**
- Pagination support
- Reactive results via publisher
- Search filtering

**Active:** Yes - Room discovery feature

---

### 19. **SecureBackup Service**

**Purpose:** Manage end-to-end encryption key backup and recovery

**Key Files:**
- `SecureBackupControllerProtocol.swift` - Service interface
- `SecureBackupController.swift` - Implementation

**Key Types:**
- `SecureBackupController` - Main backup controller
- `SecureBackupRecoveryState` - Recovery setup state
- `SecureBackupKeyBackupState` - Backup enable state
- `SecureBackupSteadyState` - Upload progress
- `SecureBackupControllerError` - Error types

**Responsibilities:**
- Enable/disable backup
- Generate recovery keys
- Confirm recovery keys
- Monitor backup upload progress
- Track recovery setup state
- Track key backup state

**Dependencies:**
- Rust SDK backup controller
- Secure backend storage

**Notable Patterns:**
- Separate recovery and backup state machines
- Progress tracking for logout flow
- Recovery key generation and validation

**Active:** Yes - Encryption key backup feature

---

### 20. **Session Service (UserSession)**

**Purpose:** Manage session persistence and restoration

**Key Files:**
- `UserSessionProtocol.swift` - Session interface
- `UserSession.swift` - Session wrapper
- `UserSessionStore.swift` - Persistence layer
- `UserSessionStoreProtocol.swift` - Store interface
- `RestorationToken.swift` - Token type
- `SessionDirectories.swift` - File organization

**Key Types:**
- `UserSession` - Active session
- `UserSessionStore` - Session persistence
- `RestorationToken` - Session restoration data
- `SessionDirectories` - File paths

**Responsibilities:**
- Create and store user sessions
- Restore sessions from tokens
- Load session from disk
- Delete sessions on logout
- Access client and media providers

**Dependencies:**
- Keychain (credential storage)
- File system (session data)
- `ClientProxy`, `MediaProvider`

**Notable Patterns:**
- Restoration token-based restoration
- File-based persistence
- Coordinated with authentication flow

**Active:** Yes - Session management

---

### 21. **SessionVerification Service**

**Purpose:** Manage device verification (emoji, QR code, passphrase verification)

**Key Files:**
- `SessionVerificationControllerProxyProtocol.swift` - Service interface
- `SessionVerificationControllerProxy.swift` - Implementation

**Key Types:**
- `SessionVerificationControllerProxy` - Verification handler
- `SessionVerificationControllerProxyAction` - Verification state changes
- `SessionVerificationControllerProxyError` - Error types
- `SessionVerificationRequestDetails` - Verification request info
- `SessionVerificationEmoji` - Emoji pair for verification

**Responsibilities:**
- Request device verification
- Accept verification requests
- Perform SAS (Short Auth String) verification
- Approve/decline/cancel verification
- Track verification emoji pairs
- Handle user verification

**Dependencies:**
- Rust SDK verification controller
- User profile data

**Notable Patterns:**
- Action-based callbacks
- Emoji localization support
- SAS verification flow

**Active:** Yes - Device verification feature

---

### 22. **Spaces Service**

**Purpose:** Manage Matrix spaces (room hierarchies)

**Key Files:**
- `SpaceServiceProxyProtocol.swift` - Service interface
- `SpaceServiceProxy.swift` - Implementation
- `SpaceRoomListProxy.swift` - Room list within space
- `SpaceRoomListProxyProtocol.swift` - Room list interface
- `LeaveSpaceHandleProxy.swift` - Leave operation
- `SpaceServiceRoom.swift` - Space metadata

**Key Types:**
- `SpaceServiceProxy` - Main space service
- `SpaceServiceRoom` - Space with metadata
- `SpaceServiceFilter` - Filtered space list
- `SpaceRoomListProxy` - Paginated room list

**Responsibilities:**
- List top-level spaces
- Get space by ID
- Join/leave spaces
- Get space parent relationships
- List editable spaces
- Manage child-parent relationships
- Filter rooms by space

**Dependencies:**
- Rust SDK space service
- Room list provider

**Notable Patterns:**
- Hierarchical filtering
- Parent-child relationships
- Editable space distinction

**Active:** Yes - Space management feature

---

### 23. **StateMachine Service**

**Purpose:** Factory for flow coordinator state machines

**Key Files:**
- `StateMachineFactory.swift` - Factory implementation

**Key Types:**
- `StateMachineFactory` - Factory implementation
- `StateMachineFactoryProtocol` - Factory interface
- `PublishedStateMachineFactory` - Testing variant

**Responsibilities:**
- Create state machines for:
  - User session flows
  - Chats tab flows
  - Room members flows
- Support testing via published state publishers

**Dependencies:**
- SwiftState library
- Flow coordinator types

**Notable Patterns:**
- Simple factory pattern
- Testing support via published states

**Active:** Yes - Core coordinator utility

---

### 24. **Timeline Service**

**Purpose:** Manage room message timelines and threading

**Key Files:**
- `TimelineProxyProtocol.swift` - Core timeline interface (~100+ lines)
- `TimelineProxy.swift` - Implementation (~400+ lines)
- `TimelineItemProviderProtocol.swift` - Item updates interface
- `TimelineItemProvider.swift` - Item management
- `TimelineItemContent/` - Message content types
- `TimelineItems/` - Timeline items (events, decorations)
- `TimelineController/` - Lower-level timeline control
- `TimelineItemIdentifier.swift` - Item identification
- `TimelineItemSender.swift` - Sender metadata
- `Fixtures/` - Test data
- `GeoURI.swift` - Location parsing
- `IntentionalMentions.swift` - @-mention tracking

**Key Types:**
- `TimelineProxy` - Main timeline interface
- `TimelineProxyProtocol` - Abstract interface
- `TimelineKind` - Live/detached/pinned/thread/media kinds
- `TimelineItemProvider` - Reactive item updates
- `TimelineItemIdentifier` - Item identification
- `TimelineController` - Lower-level control

**Responsibilities:**
- Load and display message timelines
- Handle message pagination (backwards/forwards)
- Send messages and attachments
- Edit and redact messages
- Pin/unpin messages
- Manage threads
- Manage detached timelines (search, pinned messages)
- Decrypt messages
- Fetch message details

**Dependencies:**
- Rust SDK timeline
- Media handling
- Message composition (audio, file, image, location, video)
- Timeline item factory

**Notable Patterns:**
- Kind-based timeline variants
- Item provider for reactive updates
- Separate lower-level controller
- Multiple content types supported
- Thread support via kind

**Active:** Yes - Core messaging feature

---

### 25. **Users Service**

**Purpose:** Handle user discovery and profile information

**Key Files:**
- `UserDiscoveryServiceProtocol.swift` - Service interface
- `UserDiscoveryService.swift` - Implementation
- `UserIdentityProxyProtocol.swift` - User ID interface
- `UserIdentityProxy.swift` - User identity
- `UserProfileProxy.swift` - User profile data

**Key Types:**
- `UserDiscoveryService` - User search service
- `UserProfileProxy` - User profile information
- `UserIdentityProxy` - User ID/name mapping

**Responsibilities:**
- Search user directory
- Get user profiles
- Cache user information

**Dependencies:**
- Rust SDK user discovery client

**Notable Patterns:**
- Profile caching
- Search filtering

**Active:** Yes - User discovery feature

---

### 26. **VoiceMessage Service**

**Purpose:** Record, playback, and send voice messages

**Key Files:**
- `VoiceMessageRecorderProtocol.swift` - Service interface
- `VoiceMessageRecorder.swift` - Implementation
- `VoiceMessageMediaManager.swift` - File management
- `VoiceMessageMediaManagerProtocol.swift` - Manager interface
- `VoiceMessageCache.swift` - Cache management
- `VoiceMessageCacheProtocol.swift` - Cache interface

**Key Types:**
- `VoiceMessageRecorder` - Recording and playback
- `VoiceMessageMediaManager` - File operations
- `VoiceMessageCache` - Recording cache
- `VoiceMessageRecorderError` - Error types
- `VoiceMessageRecorderAction` - State changes

**Responsibilities:**
- Start/stop voice recording
- Preview recorded audio
- Calculate waveform analysis
- Play voice message preview
- Send voice message to timeline
- Manage recording files
- Cache and cleanup

**Dependencies:**
- `AudioConverter` - Format conversion
- `AudioRecorder` - Recording device
- `TimelineController` - Message sending
- Media manager for file operations

**Notable Patterns:**
- Preview before send
- Waveform analysis
- Volatile file cleanup
- Format conversion on send

**Active:** Yes - Voice messaging feature

---

## Service Injection & Dependency Patterns

### Creation Hierarchy

```
AppCoordinator
├── Creates: ClientProxy, AnalyticsService, AppLockService
├── Injected into: UserSessionFlowCoordinator
└── Provides to: ViewModels via context

UserSession
├── Contains: ClientProxy, MediaProvider, VoiceMessageMediaManager
└── Passed to: Screens and coordinators

ClientProxy
├── Creates: RoomSummaryProvider, NotificationSettings, SpaceService
├── Manages: SyncService, RoomListService
└── Delegates to: Rust SDK
```

### Service Dependencies

**High Connectivity:**
- `ClientProxy` - Depends on 10+ services (media, notifications, verification, backup)
- `AuthenticationService` - Creates UserSession and ClientProxy
- `AnalyticsService` - Dependency injected everywhere for tracking

**Isolated Services:**
- `AppLockService` - Only depends on Keychain and AppSettings
- `Emojis` - Only depends on built-in data
- `LinkMetadata` - Only depends on LinkPresentation
- `StateMachine` - Pure factory, minimal dependencies

**Peripheral Services:**
- `BugReport` - Optional, used only when feature enabled
- `ElementCall` - Integrated but can be disabled
- `Polls` - Narrowly focused

---

## Rust SDK Integration Points

### Primary Wrappers
- **ClientProxy** → `Client` (main SDK object)
- **Timeline** → `Timeline` (room messages)
- **Room** → `Room` (room state and members)
- **NotificationSettings** → SDK notification controller
- **SecureBackup** → SDK backup controller
- **SessionVerification** → SDK verification controller

### Direct SDK Usage
- **Authentication** - Creates `Client` via factory
- **Spaces** - Uses `SpaceService` from SDK
- **Users** - Uses user discovery API
- **RoomDirectory** - Uses directory search API

### SDK Event Subscriptions
- ClientProxy subscribes to:
  - Sync updates
  - Verification state changes
  - Ignored users changes
  - Send queue status
  - Media preview config changes

---

## Mock Implementations for Testing

Most services have protocol-based mocks auto-generated via Sourcery:

```swift
// sourcery: AutoMockable
protocol MyServiceProtocol { ... }
// Generates: MyServiceProtocolMock
```

**Manual mocks:**
- `LAContextMock` - LocalAuthentication mock
- `KeychainControllerMock` - Secure storage mock
- `PublishedStateMachineFactory` - State machine testing

---

## Dead Code & Potential Issues

### Services to Investigate
1. **BugReport** - Only active if `canReportBugs` is true in build config
2. **LinkMetadata** - May not be used if link previews disabled
3. **StateMachine** - Minimal service, question if needed as separate service

### Incomplete Services
- **VoiceMessage** - Well-structured but depends on unstable audio APIs
- **ElementCall** - WebRTC complexity hidden in widget (may have integration issues)

### Services with Large Classes
- **ClientProxy** - 600+ lines, tight coupling to 10+ services
- **Timeline** - 400+ lines, handles too many concerns
- **JoinedRoomProxy** - 500+ lines, should split by responsibility

---

## Service Layer Statistics

| Metric | Value |
|--------|-------|
| Total Services | 28 |
| Protocol-based | 28 (100%) |
| Wrapping Rust SDK | 16 |
| Platform-specific | 12 |
| Core services | 8 |
| Total files | 180+ |
| Total lines | ~15,000+ |
| Largest: ElementCall | 869 lines |
| Smallest: StateMachine | 67 lines |

---

## Dependency Matrix

```
High Dependency:       Medium Dependency:     Low Dependency:
ClientProxy            Timeline               AppLock
Authentication         Room                   Keychain
UserSession            Media                  Emojis
                       Notifications          Polls
                       Spaces                 BugReport
                                             StateMachine
```

---

## Recommendations

### Architecture
1. **Split ClientProxy** - Separate room list, sync, and media concerns
2. **Timeline Refactoring** - Extract item creation and decoration logic
3. **Media Layer** - Consider separate upload/download services

### Testing
1. All services have protocol-based mocks (good for testing)
2. Some mocks could be more complete (e.g., MediaProvider)
3. Consider integration tests for SDK wrappers

### Maintenance
1. Remove or consolidate `StateMachine` service if not heavily used
2. Document Rust SDK integration points
3. Add thread safety documentation to main-actor services

### Performance
1. ClientProxy caching strategy could be optimized
2. Media cache size limits should be configurable
3. Consider lazy loading for large services like Timeline

---

## Summary

The services layer is well-structured with clear separation of concerns. Most services follow the protocol-based pattern, making them highly testable. The main architectural concern is that `ClientProxy` has become too central with too many dependencies. The layer successfully abstracts the Rust SDK, providing platform-specific interfaces for ViewModels and Coordinators.

Key strengths:
- Consistent protocol-based design
- Mock generation via Sourcery
- Clear separation between authentication, client, and data services
- Comprehensive error handling

Key areas for improvement:
- Reduce ClientProxy coupling
- Split large services (Timeline, JoinedRoomProxy)
- Document Rust SDK integration expectations
- Consider service lifecycle management
