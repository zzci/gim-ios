//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ShareExtensionConstants {
    static let urlPath = "share"
    /// Maximum byte length for URL-encoded payloads before falling back to file-based transfer.
    static let maxURLPayloadSize = 2000
    /// File name used to pass large payloads through the App Group container.
    static let payloadFileName = "sharePayload.json"

    /// URL of the payload file inside the App Group temporary directory.
    static var payloadFileURL: URL {
        URL.appGroupTemporaryDirectory.appendingPathComponent(payloadFileName)
    }
}

enum ShareExtensionPayload: Hashable, Codable {
    case mediaFiles(roomID: String?, mediaFiles: [ShareExtensionMediaFile])
    case text(roomID: String?, text: String)
    
    var roomID: String? {
        switch self {
        case .mediaFiles(let roomID, _),
             .text(let roomID, _):
            roomID
        }
    }
    
    /// Moves any files in the payload from our `appGroupTemporaryDirectory` to the
    /// system's `temporaryDirectory` returning a modified payload with updated file URLs.
    func withDefaultTemporaryDirectory() throws -> Self {
        switch self {
        case .mediaFiles(let roomID, let mediaFiles):
            return try .mediaFiles(roomID: roomID, mediaFiles: mediaFiles.map { mediaFile in
                let path = mediaFile.url.path.replacing(URL.appGroupTemporaryDirectory.path, with: "").trimmingPrefix("/")
                let newURL = URL.temporaryDirectory.appending(path: path)
                
                try? FileManager.default.removeItem(at: newURL)
                try FileManager.default.moveItem(at: mediaFile.url, to: newURL)
                
                return mediaFile.replacingURL(with: newURL)
            })
        case .text:
            return self
        }
    }
}

struct ShareExtensionMediaFile: Hashable, Codable {
    let url: URL
    let suggestedName: String?
    
    fileprivate func replacingURL(with newURL: URL) -> ShareExtensionMediaFile {
        ShareExtensionMediaFile(url: newURL, suggestedName: suggestedName)
    }
}
