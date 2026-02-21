//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ExpiringTaskRunnerError: Error {
    case timeout
}

struct ExpiringTaskRunner<T: Sendable> {
    private var task: @Sendable () async throws -> T

    init(_ task: @escaping @Sendable () async throws -> T) {
        self.task = task
    }

    func run(timeout: Duration) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await task()
            }

            group.addTask {
                try await Task.sleep(for: timeout)
                throw ExpiringTaskRunnerError.timeout
            }

            // The first task to complete wins; cancel the other.
            guard let result = try await group.next() else {
                throw ExpiringTaskRunnerError.timeout
            }
            group.cancelAll()
            return result
        }
    }
}
