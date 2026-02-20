//
// Copyright 2025 Element Creations Ltd.
// Copyright 2021-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents

/// A no-op analytics client. PostHog has been removed from GIM.
class PostHogAnalyticsClient: AnalyticsClientProtocol {
    private(set) var pendingUserProperties: AnalyticsEvent.UserProperties?

    var isRunning: Bool { false }

    func start(analyticsConfiguration: AnalyticsConfiguration) { }

    func reset() {
        pendingUserProperties = nil
    }

    func stop() { }

    func capture(_ event: AnalyticsEventProtocol) { }

    func screen(_ event: AnalyticsScreenProtocol) { }

    func updateUserProperties(_ userProperties: AnalyticsEvent.UserProperties) {
        pendingUserProperties = userProperties
    }

    func updateSuperProperties(_ updatedProperties: AnalyticsEvent.SuperProperties) { }
}
