//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CryptoKit
import Sentry

/// A simple wrapper around Sentry for easy instrumentation
class Signposter {
    /// Metadata for an active transaction including its start time for timeout reclamation.
    private struct ActiveTransaction {
        let span: any Sentry.Span
        let startDate: Date
    }

    private var transactions = [TransactionName: ActiveTransaction]()

    private var globalTags = [TagName: String]()

    /// Transactions older than this are considered leaked and will be reclaimed.
    private static let transactionTimeout: TimeInterval = 60

    enum TransactionName: Hashable {
        case cachedRoomList
        case upToDateRoomList
        case notificationToMessage
        case openRoom
        case sendMessage(uuid: String)

        var id: String {
            switch self {
            case .cachedRoomList:
                "Cached room list"
            case .upToDateRoomList:
                "Up-to-date room list"
            case .notificationToMessage:
                "Notification to message"
            case .openRoom:
                "Open a room"
            case .sendMessage:
                "Send a message"
            }
        }
    }

    enum SpanName: String {
        case timelineLoad = "Timeline load"
    }

    struct Span {
        fileprivate let innerSpan: Sentry.Span

        func finish() {
            innerSpan.finish()
        }
    }

    enum TagName: String {
        case homeserver = "Homeserver"
    }

    // MARK: - Transactions

    func startTransaction(_ transactionName: TransactionName, operation: String = "ux", tags: [TagName: String] = [:]) {
        // SENTRY-007: Duplicate start protection — finish the old transaction before replacing.
        if let existing = transactions[transactionName] {
            MXLog.warning("Signposter: duplicate start for \(transactionName.id), finishing previous transaction")
            existing.span.finish(status: .cancelled)
        }

        // Reclaim any timed-out transactions while we're here.
        reclaimTimedOutTransactions()

        let span = SentrySDK.startTransaction(name: transactionName.id, operation: operation)

        tags
            .merging(globalTags) { tagValue, _ in
                tagValue
            }
            .forEach { (key: TagName, value: String) in
                span.setTag(value: value, key: key.rawValue)
            }

        transactions[transactionName] = ActiveTransaction(span: span, startDate: Date())
    }

    func finishTransaction(_ transactionName: TransactionName) {
        transactions[transactionName]?.span.finish()
        transactions[transactionName] = nil
    }

    // MARK: - Spans

    func addSpan(_ spanName: SpanName, toTransaction transactionName: TransactionName) -> Span? {
        guard let transaction = transactions[transactionName] else {
            MXLog.error("Transaction not started or already finished")
            return nil
        }

        return Span(innerSpan: transaction.span.startChild(operation: spanName.rawValue))
    }

    // MARK: - Tags

    func addGlobalTag(_ tagName: TagName, value: String) {
        let value = switch tagName {
        case .homeserver:
            sha512(value)
        }

        globalTags[tagName] = value
    }

    func removeGlobalTag(_ tagName: TagName) {
        globalTags[tagName] = nil
    }

    // MARK: - Private

    /// Finishes and removes transactions that have been running longer than the timeout.
    private func reclaimTimedOutTransactions() {
        let now = Date()
        for (name, active) in transactions where now.timeIntervalSince(active.startDate) > Self.transactionTimeout {
            MXLog.warning("Signposter: reclaiming timed-out transaction \(name.id)")
            active.span.finish(status: .deadlineExceeded)
            transactions[name] = nil
        }
    }

    func sha512(_ string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA512.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
