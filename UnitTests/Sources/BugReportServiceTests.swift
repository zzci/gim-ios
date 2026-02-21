//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import XCTest

class BugReportServiceTests: XCTestCase {
    var bugReportService: BugReportServiceProtocol!

    override func setUpWithError() throws {
        let bugReportServiceMock = BugReportServiceMock()
        bugReportServiceMock.underlyingCrashedLastRun = false
        bugReportServiceMock.underlyingIsEnabled = true
        bugReportServiceMock.submitBugReportProgressListenerReturnValue = .success(SubmitBugReportResponse(eventID: "event-id"))
        bugReportService = bugReportServiceMock
    }

    func testInitialStateWithMockService() {
        XCTAssertFalse(bugReportService.crashedLastRun)
        XCTAssertTrue(bugReportService.isEnabled)
    }

    func testSubmitBugReportWithMockService() async throws {
        let bugReport = BugReport(userID: "@mock:client.com",
                                  deviceID: nil,
                                  ed25519: nil,
                                  curve25519: nil,
                                  text: "i cannot send message",
                                  logFiles: [URL(filePath: "/logs/1.log"), URL(filePath: "/logs/2.log")],
                                  canContact: false,
                                  githubLabels: [],
                                  files: [])
        let progressSubject = CurrentValueSubject<Double, Never>(0.0)
        let response = try await bugReportService.submitBugReport(bugReport, progressListener: progressSubject).get()
        XCTAssertEqual(response.eventID, "event-id")
    }

    func testInitialStateWithRealServiceEnabled() {
        let service = BugReportService(applicationID: "mock_app_id",
                                       sdkGitSHA: "1234",
                                       appHooks: AppHooks(),
                                       sentryEnabled: true)
        XCTAssertTrue(service.isEnabled)
        XCTAssertFalse(service.crashedLastRun)
    }

    func testInitialStateWithRealServiceDisabled() {
        let service = BugReportService(applicationID: "mock_app_id",
                                       sdkGitSHA: "1234",
                                       appHooks: AppHooks(),
                                       sentryEnabled: false)
        XCTAssertFalse(service.isEnabled)
        XCTAssertFalse(service.crashedLastRun)
    }

    func testSubmitBugReportWithRealServiceDisabled() async {
        let service = BugReportService(applicationID: "mock_app_id",
                                       sdkGitSHA: "1234",
                                       appHooks: AppHooks(),
                                       sentryEnabled: false)

        let bugReport = BugReport(userID: "@mock:client.com",
                                  deviceID: nil,
                                  ed25519: nil,
                                  curve25519: nil,
                                  text: "i cannot send message",
                                  logFiles: nil,
                                  canContact: false,
                                  githubLabels: [],
                                  files: [])

        let progressSubject = CurrentValueSubject<Double, Never>(0.0)
        switch await service.submitBugReport(bugReport, progressListener: progressSubject) {
        case .success:
            XCTFail("Expected disabled failure")
        case .failure(let error):
            XCTAssertNotNil(error.errorDescription)
        }
    }

    // MARK: - Sentry Toggle Tests

    func testSentryEnabledDefaultsToTrue() {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        XCTAssertTrue(appSettings.sentryEnabled, "Sentry should default to enabled")
    }

    func testSentryEnabledToggleOff() {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.sentryEnabled = false
        XCTAssertFalse(appSettings.sentryEnabled, "Sentry should be disabled after toggle off")
    }

    func testSentryTogglePersistsAcrossReads() {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.sentryEnabled = false

        // Read from a fresh AppSettings instance to verify persistence
        let appSettings2 = AppSettings()
        XCTAssertFalse(appSettings2.sentryEnabled, "Sentry toggle should persist")
    }

    func testSentryToggleReEnable() {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.sentryEnabled = false
        appSettings.sentryEnabled = true
        XCTAssertTrue(appSettings.sentryEnabled, "Sentry should be re-enabled after toggling back on")
    }

    func testBugReportServiceReflectsSentryToggle() {
        let enabledService = BugReportService(applicationID: "mock_app_id",
                                               sdkGitSHA: "1234",
                                               appHooks: AppHooks(),
                                               sentryEnabled: true)
        XCTAssertTrue(enabledService.isEnabled)

        let disabledService = BugReportService(applicationID: "mock_app_id",
                                                sdkGitSHA: "1234",
                                                appHooks: AppHooks(),
                                                sentryEnabled: false)
        XCTAssertFalse(disabledService.isEnabled)
    }

    func testSentryTogglePublisher() {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        let expectation = expectation(description: "sentryEnabled publisher should emit")
        var receivedValues = [Bool]()
        var cancellable: AnyCancellable?

        cancellable = appSettings.$sentryEnabled
            .dropFirst()
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 2 {
                    expectation.fulfill()
                }
            }

        appSettings.sentryEnabled = false
        appSettings.sentryEnabled = true

        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(receivedValues, [false, true])
        cancellable?.cancel()
    }
}
