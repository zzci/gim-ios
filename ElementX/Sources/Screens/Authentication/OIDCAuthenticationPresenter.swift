//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AuthenticationServices

/// Presents an ASWebAuthenticationSession for an OIDC login request.
///
/// Uses ephemeral mode so no cookies are shared with Safari or persisted.
/// After login, the Rust SDK stores access/refresh tokens in the keychain
/// via RestorationToken — no cookie persistence is needed.
@MainActor
class OIDCAuthenticationPresenter: NSObject {
    private let authenticationService: AuthenticationServiceProtocol
    private let oidcRedirectURL: URL
    private let presentationAnchor: UIWindow
    private let userIndicatorController: UserIndicatorControllerProtocol

    private var activeSession: ASWebAuthenticationSession?

    init(authenticationService: AuthenticationServiceProtocol,
         oidcRedirectURL: URL,
         presentationAnchor: UIWindow,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.authenticationService = authenticationService
        self.oidcRedirectURL = oidcRedirectURL
        self.presentationAnchor = presentationAnchor
        self.userIndicatorController = userIndicatorController
        super.init()
    }

    /// Presents a web authentication session for the supplied OIDC data and waits for the redirect callback.
    func authenticate(using oidcData: OIDCAuthorizationDataProxy) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        let (url, error) = await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(url: oidcData.url, callback: .oidcRedirectURL(oidcRedirectURL)) { url, error in
                continuation.resume(returning: (url, error))
            }

            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = self
            session.additionalHeaderFields = [
                "X-Element-User-Agent": UserAgentBuilder.makeASCIIUserAgent()
            ]

            activeSession = session
            session.start()
        }

        activeSession = nil

        guard let url else {
            if error?.isOIDCUserCancellation == true {
                await authenticationService.abortOIDCLogin(data: oidcData)
                return .failure(.oidcError(.userCancellation))
            }

            let errorDescription = error.map(String.init(describing:)) ?? "Unknown error"
            MXLog.error("Missing callback URL from the web authentication session: \(errorDescription)")

            showFailureIndicator()
            await authenticationService.abortOIDCLogin(data: oidcData)
            return .failure(.oidcError(.unknown))
        }

        // Exchanging the callback with the homeserver can be slow, show the loading indicator.
        startLoading(delay: .milliseconds(50))
        defer { stopLoading() }

        switch await authenticationService.loginWithOIDCCallback(url) {
        case .success(let userSession):
            return .success(userSession)
        case .failure(.oidcError(.userCancellation)):
            return .failure(.oidcError(.userCancellation))
        case .failure(let error):
            MXLog.error("Error occurred: \(error)")
            showFailureIndicator()
            return .failure(error)
        }
    }

    func cancel() {
        activeSession?.cancel()
    }

    // MARK: - Indicators

    private var loadingIndicatorID: String {
        "\(Self.self)-Loading"
    }

    private var failureIndicatorID: String {
        "\(Self.self)-Failure"
    }

    private func startLoading(delay: Duration? = nil) {
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorID,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: delay)
    }

    private func stopLoading() {
        userIndicatorController.retractIndicatorWithId(loadingIndicatorID)
    }

    private func showFailureIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: failureIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              iconName: "xmark"))
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension OIDCAuthenticationPresenter: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentationAnchor
    }
}

extension ASWebAuthenticationSession.Callback {
    static func oidcRedirectURL(_ url: URL) -> Self {
        if url.scheme == "https", let host = url.host() {
            .https(host: host, path: url.path())
        } else if let scheme = url.scheme {
            .customScheme(scheme)
        } else {
            fatalError("Invalid OIDC redirect URL: \(url)")
        }
    }
}

// MARK: - Helpers

extension Error {
    var isOIDCUserCancellation: Bool {
        let nsError = self as NSError

        if nsError.domain == ASWebAuthenticationSessionErrorDomain,
           nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue,
           nsError.localizedFailureReason == nil {
            return true
        }

        return false
    }
}
