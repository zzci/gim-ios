//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import GZIP
import Sentry
import UIKit

class BugReportService: NSObject, BugReportServiceProtocol {
    private static let localTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private static let utcTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private static let timeFormatterLock = NSLock()

    private let applicationID: String
    private let sdkGitSHA: String
    private let appHooks: AppHooks
    private let sentryEnabled: Bool

    var isEnabled: Bool {
        sentryEnabled
    }

    var lastCrashEventID: String?

    init(applicationID: String,
         sdkGitSHA: String,
         appHooks: AppHooks,
         sentryEnabled: Bool = true) {
        self.applicationID = applicationID
        self.sdkGitSHA = sdkGitSHA
        self.appHooks = appHooks
        self.sentryEnabled = sentryEnabled
        super.init()
    }

    // MARK: - BugReportServiceProtocol

    var crashedLastRun: Bool {
        SentrySDK.crashedLastRun
    }

    func submitBugReport(_ bugReport: BugReport,
                         progressListener: CurrentValueSubject<Double, Never>) async -> Result<SubmitBugReportResponse, BugReportServiceError> {
        guard sentryEnabled else {
            return .failure(.uploadFailure(BugReportServiceFailure.disabled))
        }

        var bugReport = appHooks.bugReportHook.update(bugReport)
        progressListener.send(0.1)

        if bugReport.userID == nil {
            bugReport.githubLabels.append("login")
        }

        if lastCrashEventID != nil {
            bugReport.githubLabels.append("crash")
        }

        if InfoPlistReader.main.baseBundleIdentifier == "im.g.message.nightly" {
            bugReport.githubLabels.append("Nightly")
        }

        if ProcessInfo.processInfo.isiOSAppOnMac {
            bugReport.githubLabels.append("macOS")
        }

        var attachments = bugReport.files
        if let logFiles = bugReport.logFiles {
            let logAttachments = await zipFiles(logFiles)
            attachments.append(contentsOf: logAttachments.files)
        }

        progressListener.send(0.6)

        let eventID = SentrySDK.capture(message: bugReport.text) { scope in
            self.configure(scope: scope,
                           bugReport: bugReport,
                           attachments: attachments)
        }

        lastCrashEventID = nil
        progressListener.send(1.0)

        MXLog.info("Feedback submitted to Sentry with event id: \(eventID.sentryIdString)")

        return .success(.init(eventID: eventID.sentryIdString))
    }

    // MARK: - Private

    private func configure(scope: Scope, bugReport: BugReport, attachments: [URL]) {
        let (localTime, utcTime) = localAndUTCTime(for: Date())

        scope.setTag(value: applicationID, key: "app")
        scope.setTag(value: GitVersion.commitHash, key: "build")
        scope.setTag(value: sdkGitSHA, key: "sdk_sha")
        scope.setTag(value: InfoPlistReader.main.baseBundleIdentifier, key: "base_bundle_identifier")

        scope.setExtra(value: "iOS", key: "user_agent")
        scope.setExtra(value: os, key: "os")
        scope.setExtra(value: "\(InfoPlistReader.main.bundleShortVersionString) (\(GitVersion.commitHash))", key: "version")
        scope.setExtra(value: Bundle.app.preferredLocalizations.joined(separator: ", "), key: "resolved_languages")
        scope.setExtra(value: Locale.preferredLanguages.joined(separator: ", "), key: "user_languages")
        scope.setExtra(value: Bundle.app.developmentLocalization ?? "null", key: "fallback_language")
        scope.setExtra(value: localTime, key: "local_time")
        scope.setExtra(value: utcTime, key: "utc_time")
        scope.setExtra(value: String(bugReport.canContact), key: "can_contact")

        if let userID = bugReport.userID {
            scope.setTag(value: userID, key: "user_id")
        }

        if let deviceID = bugReport.deviceID {
            scope.setTag(value: deviceID, key: "device_id")
        }

        if let ed25519 = bugReport.ed25519 {
            scope.setTag(value: ed25519, key: "ed25519")
        }

        if let curve25519 = bugReport.curve25519 {
            scope.setTag(value: curve25519, key: "curve25519")
        }

        if let crashEventID = lastCrashEventID {
            scope.setTag(value: crashEventID, key: "crash_report")
        }

        if !bugReport.githubLabels.isEmpty {
            scope.setExtra(value: bugReport.githubLabels.joined(separator: ","), key: "labels")
        }

        for attachmentURL in attachments {
            scope.addAttachment(SentryAttachment(path: attachmentURL.path))
        }
    }

    private func localAndUTCTime(for date: Date) -> (String, String) {
        Self.timeFormatterLock.lock()
        defer { Self.timeFormatterLock.unlock() }

        let localTime = Self.localTimeFormatter.string(from: date)
        let utcTime = Self.utcTimeFormatter.string(from: date)
        return (localTime, utcTime)
    }

    private var os: String {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)"
        } else {
            "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        }
    }

    private func zipFiles(_ logFiles: [URL]) async -> Logs {
        MXLog.info("zipFiles")

        var compressedLogs = Logs()

        for url in logFiles {
            do {
                try attachFile(at: url, to: &compressedLogs)
            } catch {
                MXLog.error("Failed to compress log at \(url)")
                // Continue so that other logs can still be sent.
            }
        }

        MXLog.info("zipFiles: originalSize: \(compressedLogs.originalSize), zippedSize: \(compressedLogs.zippedSize)")

        return compressedLogs
    }

    /// Zips a file creating chunks based on 10MB inputs.
    private func attachFile(at url: URL, to zippedFiles: inout Logs) throws {
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer { try? fileHandle.close() }

        guard let data = try fileHandle.readToEnd(),
              let zippedData = (data as NSData).gzipped() else {
            return
        }

        let zippedURL = URL.temporaryDirectory.appending(path: url.lastPathComponent)

        // Remove old zipped file if exists
        try? FileManager.default.removeItem(at: zippedURL)

        try zippedData.write(to: zippedURL)
        zippedFiles.appendFile(at: zippedURL, zippedSize: zippedData.count, originalSize: data.count)
    }

    /// A collection of logs to be uploaded to the bug report service.
    struct Logs {
        /// The files included.
        private(set) var files: [URL] = []
        /// The total size of the files after compression.
        private(set) var zippedSize = 0
        /// The original size of the files.
        private(set) var originalSize = 0

        mutating func appendFile(at url: URL, zippedSize: Int, originalSize: Int) {
            files.append(url)
            self.originalSize += originalSize
            self.zippedSize += zippedSize
        }
    }
}

private enum BugReportServiceFailure: LocalizedError {
    case disabled

    var errorDescription: String? {
        switch self {
        case .disabled:
            return "Bug report service is disabled"
        }
    }
}
