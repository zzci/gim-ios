//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// The screen shown at the beginning of the onboarding flow.
struct AuthenticationStartScreen: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @Bindable var context: AuthenticationStartScreenViewModel.Context

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                    .frame(height: UIConstants.spacerHeight(in: geometry))

                content
                    .frame(width: geometry.size.width)
                    .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.hidden)

                buttons
                    .frame(width: geometry.size.width)
                    .padding(.bottom, UIConstants.actionButtonBottomPadding)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                    .padding(.top, 8)

                Spacer()
                    .frame(height: UIConstants.spacerHeight(in: geometry))
            }
            .frame(maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    if context.viewState.showHomeserverField {
                        homeserverField
                    }

                    versionText
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                        .frame(maxWidth: .infinity)
                        .onTapGesture(count: 7) {
                            context.send(viewAction: .reportProblem)
                        }
                        .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.appVersion)
                }
                .padding(.bottom)
            }
        }
        .navigationBarHidden(true)
        .background {
            AuthenticationStartScreenBackgroundImage()
        }
        .alert(item: $context.alertInfo)
        .introspect(.window, on: .supportedVersions) { window in
            context.send(viewAction: .updateWindow(window))
        }
    }

    var content: some View {
        VStack(spacing: 0) {
            Spacer()

            if verticalSizeClass == .regular {
                Spacer()

                AuthenticationStartLogo(hideBrandChrome: context.viewState.hideBrandChrome)
            }

            Spacer()

            if !context.viewState.hideBrandChrome {
                VStack(spacing: 8) {
                    Text(L10n.screenOnboardingWelcomeTitle)
                        .font(.compound.headingLGBold)
                        .foregroundColor(.compound.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(L10n.screenOnboardingWelcomeMessage(InfoPlistReader.main.productionAppName))
                        .font(.compound.bodyLG)
                        .foregroundColor(.compound.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.bottom)
        .padding(.horizontal, 16)
        .readableFrame()
    }

    /// The main action buttons.
    var buttons: some View {
        VStack(spacing: 16) {
            if context.viewState.showQRCodeLoginButton {
                Button { context.send(viewAction: .loginWithQR) } label: {
                    Label(L10n.screenOnboardingSignInWithQrCode, icon: \.qrCode)
                }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.signInWithQr)
            }

            Button { context.send(viewAction: .login) } label: {
                Text(context.viewState.loginButtonTitle)
            }
            .buttonStyle(.compound(.primary))
            .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.signIn)

            if context.viewState.showCreateAccountButton {
                Button { context.send(viewAction: .register) } label: {
                    Text(L10n.screenCreateAccountTitle)
                }
                .buttonStyle(.compound(.tertiary))
            }
        }
        .padding(.horizontal, verticalSizeClass == .compact ? 128 : 24)
        .readableFrame()
    }

    /// The homeserver address field shown at the bottom.
    var homeserverField: some View {
        HStack(spacing: 8) {
            TextField(L10n.commonServerUrl, text: $context.homeserverAddress)
                .textFieldStyle(.element(footerText: context.viewState.homeserverFooterErrorMessage.map { Text($0) },
                                         state: context.viewState.isShowingHomeserverError ? .error : .default,
                                         accessibilityIdentifier: A11yIdentifiers.authenticationStartScreen.homeserver))
                .keyboardType(.URL)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: context.homeserverAddress) { context.send(viewAction: .clearHomeserverError) }
                .submitLabel(.go)
                .onSubmit(submitHomeserver)

            Button(action: submitHomeserver) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.compound.headingLG)
                    .foregroundColor(.compound.iconAccentPrimary)
            }
            .disabled(context.homeserverAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.homeserverConfirm)
        }
        .padding(.horizontal, 24)
        .readableFrame()
    }

    var versionText: Text {
        // Let's not deal with snapshotting a changing version string.
        let shortVersionString = ProcessInfo.isRunningTests ? "0.0.0" : InfoPlistReader.main.bundleShortVersionString
        return Text(L10n.screenOnboardingAppVersion(shortVersionString))
    }

    /// Sends the homeserver login action.
    private func submitHomeserver() {
        guard !context.homeserverAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        context.send(viewAction: .loginWithHomeserver)
    }
}

// MARK: - Previews

struct AuthenticationStartScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let provisionedViewModel = makeViewModel(provisionedServerName: "example.com")

    static var previews: some View {
        AuthenticationStartScreen(context: viewModel.context)
            .previewDisplayName("Default")
        AuthenticationStartScreen(context: provisionedViewModel.context)
            .previewDisplayName("Provisioned")
    }

    static func makeViewModel(provisionedServerName: String? = nil) -> AuthenticationStartScreenViewModel {
        AuthenticationStartScreenViewModel(authenticationService: AuthenticationService.mock,
                                           provisioningParameters: provisionedServerName.map { .init(accountProvider: $0, loginHint: nil) },
                                           isBugReportServiceEnabled: true,
                                           appSettings: ServiceLocator.shared.settings,
                                           userIndicatorController: UserIndicatorControllerMock())
    }
}
