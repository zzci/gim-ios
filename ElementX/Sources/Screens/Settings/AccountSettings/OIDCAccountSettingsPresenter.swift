//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import WebKit

/// Presents a WKWebView for the user's account settings page.
///
/// Uses a persistent WKWebsiteDataStore so that cookies are stored within the
/// app's sandbox. This provides app-level cookie persistence (no re-login each
/// time) while keeping cookies isolated from Safari. Cookies are automatically
/// deleted when the app is uninstalled.
@MainActor
class OIDCAccountSettingsPresenter: NSObject {
    private let accountURL: URL
    private let presentationAnchor: UIWindow
    private let oidcRedirectURL: URL

    typealias Continuation = AsyncStream<Result<Void, OIDCError>>.Continuation
    private let continuation: Continuation?

    private weak var presentedController: UIViewController?

    init(accountURL: URL, presentationAnchor: UIWindow, appSettings: AppSettings, continuation: Continuation? = nil) {
        self.accountURL = accountURL
        self.presentationAnchor = presentationAnchor
        oidcRedirectURL = appSettings.oidcRedirectURL
        self.continuation = continuation
        super.init()
    }

    /// Presents a WKWebView for the account settings page.
    func start() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.customUserAgent = UserAgentBuilder.makeASCIIUserAgent()

        let viewController = WebViewController(webView: webView)
        viewController.onDismiss = { [weak self] in
            self?.handleDismissal()
        }

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .formSheet

        presentedController = navigationController
        presentationAnchor.rootViewController?.present(navigationController, animated: true)

        webView.load(URLRequest(url: accountURL))
    }

    private func handleDismissal() {
        guard let continuation else { return }
        continuation.yield(.failure(.userCancellation))
        continuation.finish()
    }

    private func handleRedirect() {
        presentedController?.dismiss(animated: true)
        guard let continuation else { return }
        continuation.yield(.success(()))
        continuation.finish()
    }
}

// MARK: - WKNavigationDelegate

extension OIDCAccountSettingsPresenter: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else {
            return .allow
        }

        // Intercept the OIDC redirect URL
        if url.absoluteString.hasPrefix(oidcRedirectURL.absoluteString) {
            handleRedirect()
            return .cancel
        }

        return .allow
    }
}

// MARK: - WebViewController

/// A simple view controller that wraps a WKWebView with a Done button.
private class WebViewController: UIViewController {
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

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(doneTapped))
    }

    @objc private func doneTapped() {
        onDismiss?()
        dismiss(animated: true)
    }
}
