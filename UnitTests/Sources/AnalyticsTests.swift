//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents
@testable import ElementX
import XCTest

class AnalyticsTests: XCTestCase {
    private var appSettings: AppSettings!
    private var analyticsClient: AnalyticsClientMock!

    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()

        analyticsClient = AnalyticsClientMock()
        analyticsClient.isRunning = false
        ServiceLocator.shared.register(analytics: AnalyticsService(client: analyticsClient,
                                                                   appSettings: appSettings))
    }

    override func tearDown() {
        AppSettings.resetAllSettings()
    }

    func testAnalyticsPromptNewUser() {
        // Given a fresh install of the app (without analytics having been configured).
        // When the user is prompted for analytics.
        let showPrompt = ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt

        // Then the prompt should be shown.
        XCTAssertTrue(showPrompt, "A prompt should be shown for a new user.")
    }

    func testAnalyticsPromptUserDeclined() {
        // Given an existing install of the app where the user previously declined analytics
        appSettings.analyticsConsentState = .optedOut

        // When the user is prompted for analytics
        let showPrompt = ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt

        // Then no prompt should be shown.
        XCTAssertFalse(showPrompt, "A prompt should not be shown any more.")
    }

    func testAnalyticsPromptUserAccepted() {
        // Given an existing install of the app where the user previously accepted analytics
        appSettings.analyticsConsentState = .optedIn

        // When the user is prompted for analytics
        let showPrompt = ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt

        // Then no prompt should be shown.
        XCTAssertFalse(showPrompt, "A prompt should not be shown any more.")
    }

    func testAnalyticsPromptNotDisplayed() {
        // Given a fresh install of the app Analytics should be disabled
        XCTAssertEqual(appSettings.analyticsConsentState, .unknown)
        XCTAssertFalse(ServiceLocator.shared.analytics.isEnabled)
        XCTAssertFalse(analyticsClient.startAnalyticsConfigurationCalled)
    }

    func testAnalyticsOptOut() {
        // Given a fresh install of the app (without analytics having been configured).
        // When analytics is opt-out
        ServiceLocator.shared.analytics.optOut()
        // Then analytics should be disabled
        XCTAssertEqual(appSettings.analyticsConsentState, .optedOut)
        XCTAssertFalse(ServiceLocator.shared.analytics.isEnabled)
        XCTAssertFalse(analyticsClient.isRunning)
        // Analytics client should have been stopped
        XCTAssertTrue(analyticsClient.stopCalled)
    }

    func testAnalyticsOptIn() {
        // Given a fresh install of the app (without analytics having been configured).
        // When analytics is opt-in
        ServiceLocator.shared.analytics.optIn()
        // The analytics should be enabled
        XCTAssertEqual(appSettings.analyticsConsentState, .optedIn)
        XCTAssertTrue(ServiceLocator.shared.analytics.isEnabled)
        // Analytics client should have been started
        XCTAssertTrue(analyticsClient.startAnalyticsConfigurationCalled)
    }

    func testAnalyticsStartIfNotEnabled() {
        // Given an existing install of the app where the user previously declined the tracking
        appSettings.analyticsConsentState = .optedOut
        // Analytics should not start
        XCTAssertFalse(ServiceLocator.shared.analytics.isEnabled)
        ServiceLocator.shared.analytics.startIfEnabled()
        XCTAssertFalse(analyticsClient.startAnalyticsConfigurationCalled)
    }

    func testAnalyticsStartIfEnabled() {
        // Given an existing install of the app where the user previously accepted the tracking
        appSettings.analyticsConsentState = .optedIn
        // Analytics should start
        XCTAssertTrue(ServiceLocator.shared.analytics.isEnabled)
        ServiceLocator.shared.analytics.startIfEnabled()
        XCTAssertTrue(analyticsClient.startAnalyticsConfigurationCalled)
    }

    func testAddingUserProperties() {
        // Given a client with no user properties set
        let client = NoopAnalyticsClient()
        XCTAssertNil(client.pendingUserProperties, "No user properties should have been set yet.")

        // When updating the user properties
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil,
                                                                  ftueUseCaseSelection: .PersonalMessaging,
                                                                  numFavouriteRooms: 4,
                                                                  numSpaces: 5, recoveryState: .Disabled, verificationState: .Verified))

        // Then the properties should be cached
        XCTAssertNotNil(client.pendingUserProperties, "The user properties should be cached.")
        XCTAssertEqual(client.pendingUserProperties?.ftueUseCaseSelection, .PersonalMessaging, "The use case selection should match.")
        XCTAssertEqual(client.pendingUserProperties?.numFavouriteRooms, 4, "The number of favorite rooms should match.")
        XCTAssertEqual(client.pendingUserProperties?.numSpaces, 5, "The number of spaces should match.")
        XCTAssertEqual(client.pendingUserProperties?.verificationState, AnalyticsEvent.UserProperties.VerificationState.Verified, "The verification state should match.")
        XCTAssertEqual(client.pendingUserProperties?.recoveryState, AnalyticsEvent.UserProperties.RecoveryState.Disabled, "The recovery state should match.")
    }

    func testMergingUserProperties() {
        // Given a client with a cached use case user properties
        let client = NoopAnalyticsClient()
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: .PersonalMessaging,
                                                                  numFavouriteRooms: nil,
                                                                  numSpaces: nil, recoveryState: nil, verificationState: nil))

        XCTAssertNotNil(client.pendingUserProperties, "The user properties should be cached.")
        XCTAssertEqual(client.pendingUserProperties?.ftueUseCaseSelection, .PersonalMessaging, "The use case selection should match.")
        XCTAssertNil(client.pendingUserProperties?.numFavouriteRooms, "The number of favorite rooms should not be set.")
        XCTAssertNil(client.pendingUserProperties?.numSpaces, "The number of spaces should not be set.")

        // When updating the number of spaces
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: nil,
                                                                  numFavouriteRooms: 4,
                                                                  numSpaces: 5, recoveryState: nil, verificationState: nil))

        // Then the new properties should be updated and the existing properties should remain unchanged
        XCTAssertNotNil(client.pendingUserProperties, "The user properties should be cached.")
        XCTAssertEqual(client.pendingUserProperties?.ftueUseCaseSelection, .PersonalMessaging, "The use case selection shouldn't have changed.")
        XCTAssertEqual(client.pendingUserProperties?.numFavouriteRooms, 4, "The number of favorite rooms should have been updated.")
        XCTAssertEqual(client.pendingUserProperties?.numSpaces, 5, "The number of spaces should have been updated.")
    }

    func testResetConsentState() {
        // Given an existing install of the app where the user previously accepted the tracking
        appSettings.analyticsConsentState = .optedIn
        XCTAssertFalse(ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt)

        // When forgetting analytics consents
        ServiceLocator.shared.analytics.resetConsentState()

        // Then the analytics prompt should be presented again
        XCTAssertEqual(appSettings.analyticsConsentState, .unknown)
        XCTAssertTrue(ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt)
    }

    func testNoopClientReset() {
        // Given a no-op client with cached user properties
        let client = NoopAnalyticsClient()
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil,
                                                                  ftueUseCaseSelection: .PersonalMessaging,
                                                                  numFavouriteRooms: nil,
                                                                  numSpaces: nil, recoveryState: nil, verificationState: nil))
        XCTAssertNotNil(client.pendingUserProperties)

        // When resetting the client
        client.reset()

        // Then the cached properties should be cleared
        XCTAssertNil(client.pendingUserProperties, "User properties should be cleared after reset.")
    }

    func testNoopClientIsNeverRunning() {
        // Given a no-op analytics client
        let client = NoopAnalyticsClient()

        // The client should never report as running
        XCTAssertFalse(client.isRunning, "No-op client should never be running.")

        // Even after start is called
        client.start(analyticsConfiguration: AnalyticsConfiguration(host: "test", apiKey: "test"))
        XCTAssertFalse(client.isRunning, "No-op client should still not be running after start.")
    }
}
