//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct PreAuthDiagnosticsScreenCoordinatorParameters {
    let bugReportService: BugReportServiceProtocol
    let appSettings: AppSettings
}

final class PreAuthDiagnosticsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: PreAuthDiagnosticsScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()

    private let actionsSubject: PassthroughSubject<PreAuthDiagnosticsScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<PreAuthDiagnosticsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(parameters: PreAuthDiagnosticsScreenCoordinatorParameters) {
        viewModel = PreAuthDiagnosticsScreenViewModel(
            bugReportService: parameters.bugReportService,
            appSettings: parameters.appSettings
        )
    }

    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .dismiss:
                    actionsSubject.send(.dismiss)
                case .viewLogs:
                    actionsSubject.send(.viewLogs)
                }
            }
            .store(in: &cancellables)
    }

    func toPresentable() -> AnyView {
        AnyView(PreAuthDiagnosticsScreen(context: viewModel.context))
    }
}
