//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias PreAuthDiagnosticsScreenViewModelType = StateStoreViewModelV2<PreAuthDiagnosticsScreenViewState, PreAuthDiagnosticsScreenViewAction>

class PreAuthDiagnosticsScreenViewModel: PreAuthDiagnosticsScreenViewModelType, PreAuthDiagnosticsScreenViewModelProtocol {
    private let bugReportService: BugReportServiceProtocol
    private let appSettings: AppSettings

    private let actionsSubject: PassthroughSubject<PreAuthDiagnosticsScreenViewModelAction, Never> = .init()

    // periphery:ignore - when set to nil this is automatically cancelled
    @CancellableTask private var uploadTask: Task<Void, Never>?

    var actions: AnyPublisher<PreAuthDiagnosticsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(bugReportService: BugReportServiceProtocol,
         appSettings: AppSettings) {
        self.bugReportService = bugReportService
        self.appSettings = appSettings

        let initialViewState = PreAuthDiagnosticsScreenViewState(
            bindings: .init(sentryEnabled: appSettings.sentryEnabled)
        )

        super.init(initialViewState: initialViewState)
    }

    override func process(viewAction: PreAuthDiagnosticsScreenViewAction) {
        switch viewAction {
        case .dismiss:
            actionsSubject.send(.dismiss)
        case .toggleSentry(let enabled):
            appSettings.sentryEnabled = enabled
            state.bindings.sentryEnabled = enabled
            MXLog.info("Sentry toggled to \(enabled) from pre-auth diagnostics")
            showRestartAlert()
        case .sendLogs:
            state.uploadResult = nil
            state.isUploadingLogs = true
            uploadTask = Task { await uploadLogs() }
        case .viewLogs:
            actionsSubject.send(.viewLogs)
        case .clearUploadResult:
            state.uploadResult = nil
        }
    }

    // MARK: - Private

    private func showRestartAlert() {
        state.bindings.alertInfo = AlertInfo(
            id: .restartRequired,
            title: "Restart Required",
            message: "The error reporting setting change will take full effect after restarting the app."
        )
    }

    private func uploadLogs() async {
        let logFiles = Tracing.logFiles
        let progressSubject = CurrentValueSubject<Double, Never>(0.0)

        let bugReport = BugReport(
            userID: nil,
            deviceID: nil,
            ed25519: nil,
            curve25519: nil,
            text: "[Pre-auth diagnostics] Log upload",
            logFiles: logFiles,
            canContact: false,
            githubLabels: ["pre-auth"],
            files: []
        )

        switch await bugReportService.submitBugReport(bugReport, progressListener: progressSubject) {
        case .success(let response):
            MXLog.info("Pre-auth log upload succeeded: \(response.eventID ?? "no event ID")")
            state.isUploadingLogs = false
            state.uploadResult = .success(eventID: response.eventID ?? "")
        case .failure(let error):
            MXLog.error("Pre-auth log upload failed: \(error)")
            state.isUploadingLogs = false
            state.uploadResult = .failure(message: error.localizedDescription)
        }
    }
}
