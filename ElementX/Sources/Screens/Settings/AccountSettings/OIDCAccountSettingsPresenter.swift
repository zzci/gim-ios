//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AuthenticationServices

/// Presents an ASWebAuthenticationSession for the user's account settings page.
///
/// Uses ephemeral mode so no cookies are shared with Safari or persisted.
/// The account management URL from the SDK includes authentication hints,
/// so the OIDC provider can identify the user without persistent cookies.
@MainActor
class OIDCAccountSettingsPresenter: NSObject {
    private let accountURL: URL
    private let presentationAnchor: UIWindow
    private let oidcRedirectURL: URL

    typealias Continuation = AsyncStream<Result<Void, OIDCError>>.Continuation
    private let continuation: Continuation?

    init(accountURL: URL, presentationAnchor: UIWindow, appSettings: AppSettings, continuation: Continuation? = nil) {
        self.accountURL = accountURL
        self.presentationAnchor = presentationAnchor
        oidcRedirectURL = appSettings.oidcRedirectURL
        self.continuation = continuation
        super.init()
    }

    /// Presents a web authentication session for the account settings page.
    func start() {
        let session = ASWebAuthenticationSession(url: accountURL, callback: .oidcRedirectURL(oidcRedirectURL)) { [continuation] _, error in
            guard let continuation else { return }

            if error?.isOIDCUserCancellation == true {
                continuation.yield(.failure(.userCancellation))
            } else {
                // User closed the session or an error occurred — treat as success
                // since the account management action may have already completed.
                continuation.yield(.success(()))
            }

            continuation.finish()
        }

        session.prefersEphemeralWebBrowserSession = true
        session.presentationContextProvider = self
        session.additionalHeaderFields = [
            "X-Element-User-Agent": UserAgentBuilder.makeASCIIUserAgent()
        ]

        session.start()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension OIDCAccountSettingsPresenter: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentationAnchor
    }
}
