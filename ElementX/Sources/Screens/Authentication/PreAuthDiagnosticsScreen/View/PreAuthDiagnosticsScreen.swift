//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct PreAuthDiagnosticsScreen: View {
    @Bindable var context: PreAuthDiagnosticsScreenViewModel.Context

    var body: some View {
        Form {
            sentrySection
            logsSection
            uploadResultSection
        }
        .compoundList()
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
    }

    // MARK: - Sections

    private var sentrySection: some View {
        Section {
            ListRow(label: .plain(title: "Error reporting"),
                    kind: .toggle(Binding(
                        get: { context.viewState.bindings.sentryEnabled },
                        set: { context.send(viewAction: .toggleSentry($0)) }
                    )))
        } footer: {
            Text("When enabled, anonymous crash reports and diagnostics are sent to help improve the app. Changes take full effect after restarting.")
                .compoundListSectionFooter()
        }
    }

    private var logsSection: some View {
        Section {
            ListRow(label: .plain(title: "Send logs"),
                    kind: .button {
                        context.send(viewAction: .sendLogs)
                    })
                .disabled(context.viewState.isUploadingLogs)

            ListRow(label: .plain(title: L10n.screenBugReportViewLogs),
                    kind: .navigationLink {
                        context.send(viewAction: .viewLogs)
                    })
        } footer: {
            if context.viewState.isUploadingLogs {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Uploading logs...")
                }
                .compoundListSectionFooter()
            } else {
                Text("Upload device logs to help diagnose login issues. No account information is included.")
                    .compoundListSectionFooter()
            }
        }
    }

    @ViewBuilder
    private var uploadResultSection: some View {
        if let result = context.viewState.uploadResult {
            Section {
                switch result {
                case .success(let eventID):
                    ListRow(kind: .custom {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Logs uploaded successfully")
                                    .font(.compound.bodyLG)
                                    .foregroundStyle(.compound.textPrimary)
                                if !eventID.isEmpty {
                                    Text("Event ID: \(eventID)")
                                        .font(.compound.bodySM)
                                        .foregroundStyle(.compound.textSecondary)
                                }
                            }
                        } icon: {
                            CompoundIcon(\.checkCircleSolid, size: .medium, relativeTo: .compound.bodyLG)
                                .foregroundStyle(.compound.iconSuccessPrimary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    })
                case .failure(let message):
                    ListRow(kind: .custom {
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text("Upload failed")
                                    .font(.compound.bodyLG)
                                    .foregroundStyle(.compound.textCriticalPrimary)
                            } icon: {
                                CompoundIcon(\.errorSolid, size: .medium, relativeTo: .compound.bodyLG)
                                    .foregroundStyle(.compound.iconCriticalPrimary)
                            }

                            Text(message)
                                .font(.compound.bodySM)
                                .foregroundStyle(.compound.textSecondary)

                            Button {
                                context.send(viewAction: .sendLogs)
                            } label: {
                                Text(L10n.actionRetry)
                            }
                            .buttonStyle(.compound(.secondary, size: .medium))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    })
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionClose) {
                context.send(viewAction: .dismiss)
            }
        }
    }
}

// MARK: - Previews

struct PreAuthDiagnosticsScreen_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        ElementNavigationStack {
            PreAuthDiagnosticsScreen(context: PreAuthDiagnosticsScreenViewModel(
                bugReportService: BugReportServiceMock(.init()),
                appSettings: ServiceLocator.shared.settings
            ).context)
        }
        .previewDisplayName("Default")
    }
}
