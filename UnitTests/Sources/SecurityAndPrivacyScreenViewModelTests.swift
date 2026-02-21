//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import XCTest

@MainActor
class SecurityAndPrivacyScreenViewModelTests: XCTestCase {
    var viewModel: SecurityAndPrivacyScreenViewModelProtocol!
    var roomProxy: JoinedRoomProxyMock!

    var context: SecurityAndPrivacyScreenViewModelType.Context {
        viewModel.context
    }

    override func tearDown() {
        viewModel = nil
        roomProxy = nil
        AppSettings.resetAllSettings()
    }

    func testSave() async throws {
        setupViewModel(joinRule: .public)
        
        // Saving shouldn't dismiss this screen (or trigger any other action).
        let deferred = deferFailure(viewModel.actionsPublisher, timeout: 1) { _ in true }
        
        context.desiredSettings.accessType = .inviteOnly
        context.send(viewAction: .save)
        
        try await deferred.fulfill()
    }
    
    func testCancelWithChangesAndDiscard() async throws {
        setupViewModel(joinRule: .public)
        context.desiredSettings.accessType = .inviteOnly
        XCTAssertFalse(context.viewState.isSaveDisabled)
        XCTAssertNil(context.alertInfo)
        
        context.send(viewAction: .cancel)
        
        XCTAssertNotNil(context.alertInfo)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) {
            switch $0 {
            case .dismiss:
                true
            default:
                false
            }
        }
        context.alertInfo?.secondaryButton?.action?() // Discard
        try await deferred.fulfill()
    }
    
    func testCancelWithChangesAndSave() async throws {
        setupViewModel(joinRule: .public)
        context.desiredSettings.accessType = .inviteOnly
        XCTAssertFalse(context.viewState.isSaveDisabled)
        XCTAssertNil(context.alertInfo)
        
        context.send(viewAction: .cancel)
        
        XCTAssertNotNil(context.alertInfo)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) {
            switch $0 {
            case .dismiss:
                true
            default:
                false
            }
        }
        context.alertInfo?.primaryButton.action?() // Save
        try await deferred.fulfill()
    }
    
    func testCancelWithChangesAndSaveWithFailure() async throws {
        setupViewModel(joinRule: .public)
        roomProxy.updateJoinRuleReturnValue = .failure(.sdkError(RoomProxyMockError.generic))
        context.desiredSettings.accessType = .inviteOnly
        XCTAssertFalse(context.viewState.isSaveDisabled)
        XCTAssertNil(context.alertInfo)
        
        context.send(viewAction: .cancel)
        
        XCTAssertNotNil(context.alertInfo)
        
        // The screen should not be dismissed if a failure occurred.
        let deferred = deferFailure(viewModel.actionsPublisher, timeout: 1) { _ in true }
        context.alertInfo?.primaryButton.action?() // Save
        try await deferred.fulfill()
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(joinRule: ElementX.JoinRule) {
        let appSettings = AppSettings()
        appSettings.knockingEnabled = true
        roomProxy = JoinedRoomProxyMock(.init(isEncrypted: false,
                                              canonicalAlias: "#room:matrix.org",
                                              members: .allMembersAsCreator,
                                              joinRule: joinRule,
                                              isVisibleInPublicDirectory: true))
        roomProxy.updateJoinRuleReturnValue = .success(())
        roomProxy.updateRoomDirectoryVisibilityReturnValue = .success(())

        viewModel = SecurityAndPrivacyScreenViewModel(roomProxy: roomProxy,
                                                      clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                      userIndicatorController: UserIndicatorControllerMock(),
                                                      appSettings: appSettings)
    }
}
