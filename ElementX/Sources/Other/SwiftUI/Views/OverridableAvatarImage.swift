//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct OverridableAvatarImage: View {
    let overrideURL: URL?
    let url: URL?
    let name: String?
    let contentID: String
    let shape: LoadableAvatarImage.Shape
    let avatarSize: Avatars.Size
    let mediaProvider: MediaProviderProtocol?

    var body: some View {
        if let overrideURL {
            LocalImage(url: overrideURL, name: name, contentID: contentID)
                .scaledFrame(size: avatarSize.value)
                .avatarShape(shape, size: avatarSize.value)
        } else {
            LoadableAvatarImage(url: url,
                                name: name,
                                contentID: contentID,
                                shape: shape,
                                avatarSize: avatarSize,
                                mediaProvider: mediaProvider)
        }
    }
}

/// Loads a local file URL image asynchronously, replacing AsyncImage
/// with a pattern that avoids its lack of caching.
private struct LocalImage: View {
    let url: URL
    let name: String?
    let contentID: String

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                PlaceholderAvatarImage(name: name, contentID: contentID)
            }
        }
        .task(id: url) {
            image = await loadImage(from: url)
        }
    }

    private func loadImage(from url: URL) async -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
