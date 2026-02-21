//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias AuthenticationStartScreenViewModelType = StateStoreViewModelV2<AuthenticationStartScreenViewState, AuthenticationStartScreenViewAction>

class AuthenticationStartScreenViewModel: AuthenticationStartScreenViewModelType, AuthenticationStartScreenViewModelProtocol {
    private let authenticationService: AuthenticationServiceProtocol
    private let provisioningParameters: AccountProvisioningParameters?
    private let appSettings: AppSettings
    private let userIndicatorController: UserIndicatorControllerProtocol

    private let canReportProblem: Bool

    private var actionsSubject: PassthroughSubject<AuthenticationStartScreenViewModelAction, Never> = .init()

    var actions: AnyPublisher<AuthenticationStartScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(authenticationService: AuthenticationServiceProtocol,
         provisioningParameters: AccountProvisioningParameters?,
         isBugReportServiceEnabled: Bool,
         appSettings: AppSettings,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.authenticationService = authenticationService
        self.provisioningParameters = provisioningParameters
        self.appSettings = appSettings
        self.userIndicatorController = userIndicatorController
        canReportProblem = isBugReportServiceEnabled

        let isQRCodeScanningSupported = !ProcessInfo.processInfo.isiOSAppOnMac
        let defaultHomeserver = authenticationService.homeserver.value.address

        let initialViewState = AuthenticationStartScreenViewState(showQRCodeLoginButton: isQRCodeScanningSupported,
                                                                   hideBrandChrome: appSettings.hideBrandChrome,
                                                                   bindings: .init(homeserverAddress: defaultHomeserver))

        super.init(initialViewState: initialViewState)
    }

    override func process(viewAction: AuthenticationStartScreenViewAction) {
        switch viewAction {
        case .updateWindow(let window):
            guard state.window != window else { return }
            state.window = window
        case .loginWithQR:
            actionsSubject.send(.loginWithQR)
        case .reportProblem:
            if canReportProblem {
                actionsSubject.send(.reportProblem)
            }
        case .diagnostics:
            actionsSubject.send(.diagnostics)
        case .clearHomeserverError:
            clearHomeserverError()
        case .loginWithHomeserver:
            Task { await loginWithCustomHomeserver() }
        }
    }

    // MARK: - Private

    private func loginWithCustomHomeserver() async {
        let homeserverAddress = state.bindings.homeserverAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !homeserverAddress.isEmpty else { return }

        startLoading()
        defer { stopLoading() }

        switch await authenticationService.configure(for: homeserverAddress, flow: .login) {
        case .success:
            let loginMode = authenticationService.homeserver.value.loginMode
            MXLog.info("Homeserver configured successfully, loginMode: \(loginMode)")

            guard loginMode.supportsOIDCFlow else {
                actionsSubject.send(.loginDirectlyWithPassword(loginHint: nil))
                return
            }

            guard let window = resolveWindow() else {
                MXLog.error("OIDC login failed: no presentation window available")
                displayError(.genericError)
                return
            }

            switch await authenticationService.urlForOIDCLogin(loginHint: nil) {
            case .success(let oidcData):
                actionsSubject.send(.loginDirectlyWithOIDC(data: oidcData, window: window))
            case .failure(let error):
                MXLog.error("OIDC URL generation failed: \(error)")
                displayError(.genericError)
            }
        case .failure(let error):
            MXLog.error("Homeserver configuration failed: \(error)")
            handleHomeserverError(error)
        }
    }

    /// Returns the presentation window, falling back to the key window if introspection hasn't fired.
    private func resolveWindow() -> UIWindow? {
        if let window = state.window {
            return window
        }
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        if let window {
            state.window = window
        }
        return window
    }

    private func configureAccountProvider(_ accountProvider: String, loginHint: String? = nil) async {
        startLoading()
        defer { stopLoading() }

        guard case .success = await authenticationService.configure(for: accountProvider, flow: .login) else {
            displayError(.genericError)
            return
        }

        guard authenticationService.homeserver.value.loginMode.supportsOIDCFlow else {
            actionsSubject.send(.loginDirectlyWithPassword(loginHint: loginHint))
            return
        }

        guard let window = resolveWindow() else {
            MXLog.error("OIDC login failed: no presentation window available")
            displayError(.genericError)
            return
        }

        switch await authenticationService.urlForOIDCLogin(loginHint: loginHint) {
        case .success(let oidcData):
            actionsSubject.send(.loginDirectlyWithOIDC(data: oidcData, window: window))
        case .failure(let error):
            MXLog.error("OIDC URL generation failed: \(error)")
            displayError(.genericError)
        }
    }

    private func handleHomeserverError(_ error: AuthenticationServiceError) {
        switch error {
        case .invalidServer, .invalidHomeserverAddress:
            showHomeserverFooterError(L10n.screenChangeServerErrorInvalidHomeserver)
        case .invalidWellKnown(let error):
            displayError(.invalidWellKnown(error))
        case .slidingSyncNotAvailable:
            displayError(.slidingSync)
        case .loginNotSupported:
            displayError(.loginNotSupported)
        case .elementProRequired(let serverName):
            displayError(.elementProRequired(serverName: serverName))
        default:
            displayError(.genericError)
        }
    }

    private func showHomeserverFooterError(_ message: String) {
        withElementAnimation {
            state.homeserverFooterErrorMessage = message
        }
    }

    private func clearHomeserverError() {
        guard state.homeserverFooterErrorMessage != nil else { return }
        withElementAnimation { state.homeserverFooterErrorMessage = nil }
    }

    private let loadingIndicatorID = "\(AuthenticationStartScreenViewModel.self)-Loading"

    private func startLoading() {
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorID,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }

    private func stopLoading() {
        userIndicatorController.retractIndicatorWithId(loadingIndicatorID)
    }

    private func displayError(_ type: AuthenticationStartScreenAlertType) {
        switch type {
        case .invalidWellKnown(let error):
            state.bindings.alertInfo = AlertInfo(id: .invalidWellKnown(error),
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorInvalidWellKnown(error))
        case .slidingSync:
            let nonBreakingAppName = InfoPlistReader.main.bundleDisplayName.replacingOccurrences(of: " ", with: "\u{00A0}")
            state.bindings.alertInfo = AlertInfo(id: .slidingSync,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorNoSlidingSyncMessage(nonBreakingAppName))
        case .loginNotSupported:
            state.bindings.alertInfo = AlertInfo(id: .loginNotSupported,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenLoginErrorUnsupportedAuthentication)
        case .elementProRequired(let serverName):
            state.bindings.alertInfo = AlertInfo(id: .elementProRequired(serverName: serverName),
                                                 title: L10n.screenChangeServerErrorElementProRequiredTitle,
                                                 message: L10n.screenChangeServerErrorElementProRequiredMessage(serverName),
                                                 primaryButton: .init(title: L10n.screenChangeServerErrorElementProRequiredActionIos) {
                                                     UIApplication.shared.open(self.appSettings.elementProAppStoreURL)
                                                 },
                                                 secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        case .genericError:
            state.bindings.alertInfo = AlertInfo(id: .genericError)
        }
    }
}
