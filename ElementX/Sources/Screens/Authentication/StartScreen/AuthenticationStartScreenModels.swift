//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

// MARK: - Coordinator

enum AuthenticationStartScreenCoordinatorAction {
    case loginWithQR
    case reportProblem

    case loginDirectlyWithOIDC(data: OIDCAuthorizationDataProxy, window: UIWindow)
    case loginDirectlyWithPassword(loginHint: String?)
}

enum AuthenticationStartScreenViewModelAction: Equatable {
    case loginWithQR
    case reportProblem

    case loginDirectlyWithOIDC(data: OIDCAuthorizationDataProxy, window: UIWindow)
    case loginDirectlyWithPassword(loginHint: String?)
}

struct AuthenticationStartScreenViewState: BindableState {
    /// The presentation anchor used for OIDC authentication.
    var window: UIWindow?

    let showQRCodeLoginButton: Bool

    let hideBrandChrome: Bool

    var bindings = AuthenticationStartScreenViewStateBindings()

    /// An error message to be shown in the homeserver text field footer.
    var homeserverFooterErrorMessage: String?

    /// Whether the homeserver text field is showing an error.
    var isShowingHomeserverError: Bool {
        homeserverFooterErrorMessage != nil
    }
}

struct AuthenticationStartScreenViewStateBindings {
    /// The homeserver address input by the user.
    var homeserverAddress = ""
    var alertInfo: AlertInfo<AuthenticationStartScreenAlertType>?
}

enum AuthenticationStartScreenAlertType: Hashable {
    case genericError
    case invalidWellKnown(String)
    case slidingSync
    case loginNotSupported
    case elementProRequired(serverName: String)
}

enum AuthenticationStartScreenViewAction {
    /// Updates the window used as the OIDC presentation anchor.
    case updateWindow(UIWindow)

    case loginWithQR
    case reportProblem

    /// Clear any homeserver footer errors when editing the text field.
    case clearHomeserverError
    /// The user tapped the login button after entering a custom homeserver.
    case loginWithHomeserver
}
