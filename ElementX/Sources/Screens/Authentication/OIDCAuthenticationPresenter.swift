//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import WebKit

/// Presents a WKWebView for an OIDC login request.
///
/// Uses a persistent WKWebsiteDataStore so that cookies are stored within the
/// app's sandbox. This means the OIDC provider's session cookie persists across
/// app launches — if the user needs to re-authenticate, they won't have to
/// re-enter credentials. Cookies are isolated from Safari and automatically
/// deleted when the app is uninstalled.
@MainActor
class OIDCAuthenticationPresenter: NSObject {
    private let authenticationService: AuthenticationServiceProtocol
    private let oidcRedirectURL: URL
    private let presentationAnchor: UIWindow
    private let userIndicatorController: UserIndicatorControllerProtocol

    private weak var presentedController: UIViewController?
    private var authContinuation: CheckedContinuation<(URL?, Bool), Never>?

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

    /// Presents a WKWebView for the supplied OIDC data and waits for the redirect callback.
    func authenticate(using oidcData: OIDCAuthorizationDataProxy) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        let (callbackURL, cancelled) = await withCheckedContinuation { (continuation: CheckedContinuation<(URL?, Bool), Never>) in
            authContinuation = continuation

            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = .default()

            let webView = WKWebView(frame: .zero, configuration: configuration)
            webView.navigationDelegate = self
            webView.customUserAgent = UserAgentBuilder.makeASCIIUserAgent()

            let viewController = OIDCWebViewController(webView: webView)
            viewController.onDismiss = { [weak self] in
                guard let self, let authContinuation else { return }
                self.authContinuation = nil
                authContinuation.resume(returning: (nil, true))
            }

            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .formSheet

            presentedController = navigationController
            presentationAnchor.rootViewController?.present(navigationController, animated: true)

            webView.load(URLRequest(url: oidcData.url))
        }

        guard let callbackURL, !cancelled else {
            await authenticationService.abortOIDCLogin(data: oidcData)
            return .failure(.oidcError(.userCancellation))
        }

        // Exchanging the callback with the homeserver can be slow, so show the loading indicator while we wait.
        startLoading(delay: .milliseconds(50))
        defer { stopLoading() }

        switch await authenticationService.loginWithOIDCCallback(callbackURL) {
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
        presentedController?.dismiss(animated: true)
        guard let authContinuation else { return }
        self.authContinuation = nil
        authContinuation.resume(returning: (nil, true))
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

// MARK: - WKNavigationDelegate

extension OIDCAuthenticationPresenter: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else {
            return .allow
        }

        // Intercept the OIDC redirect URL
        if url.absoluteString.hasPrefix(oidcRedirectURL.absoluteString) {
            presentedController?.dismiss(animated: true)
            guard let authContinuation else { return .cancel }
            self.authContinuation = nil
            authContinuation.resume(returning: (url, false))
            return .cancel
        }

        return .allow
    }
}

// MARK: - OIDCWebViewController

/// A simple view controller that wraps a WKWebView with a Cancel button.
private class OIDCWebViewController: UIViewController {
    private let webView: WKWebView
    var onDismiss: (() -> Void)?

    init(webView: WKWebView) {
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(cancelTapped))
    }

    @objc private func cancelTapped() {
        onDismiss?()
        dismiss(animated: true)
    }
}
