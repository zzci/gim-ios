//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

enum PreAuthDiagnosticsScreenCoordinatorAction {
    case dismiss
    case viewLogs
}

enum PreAuthDiagnosticsScreenViewModelAction {
    case dismiss
    case viewLogs
}

struct PreAuthDiagnosticsScreenViewState: BindableState {
    var bindings = PreAuthDiagnosticsScreenViewStateBindings()

    /// Whether a log upload is currently in progress.
    var isUploadingLogs = false
    /// Result feedback after a log upload attempt.
    var uploadResult: LogUploadResult?

    enum LogUploadResult: Equatable {
        case success(eventID: String)
        case failure(message: String)
    }
}

struct PreAuthDiagnosticsScreenViewStateBindings {
    var sentryEnabled = true
    var alertInfo: AlertInfo<PreAuthDiagnosticsScreenAlertType>?
}

enum PreAuthDiagnosticsScreenAlertType: Hashable {
    case restartRequired
}

enum PreAuthDiagnosticsScreenViewAction {
    case dismiss
    case toggleSentry(Bool)
    case sendLogs
    case viewLogs
    case clearUploadResult
}
