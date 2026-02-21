//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import MapKit
import SwiftUI

struct MapSnapshotView<PinAnnotation: View>: View {
    private let coordinates: CLLocationCoordinate2D
    private let zoomLevel: Double
    private let mapSize: CGSize
    private let pinAnnotationView: PinAnnotation

    @Environment(\.colorScheme) private var colorScheme
    @State private var snapshotImage: UIImage?
    @State private var isLoading = true
    @State private var hasError = false

    init(coordinates: CLLocationCoordinate2D,
         zoomLevel: Double,
         mapSize: CGSize,
         @ViewBuilder pinAnnotationView: () -> PinAnnotation) {
        self.coordinates = coordinates
        self.zoomLevel = zoomLevel
        self.mapSize = mapSize
        self.pinAnnotationView = pinAnnotationView()
    }

    var body: some View {
        ZStack {
            if let snapshotImage {
                Image(uiImage: snapshotImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)

                pinAnnotationView
            } else if hasError {
                errorView
            } else {
                placeholderImage
            }
        }
        .task(id: snapshotCacheKey) {
            await loadSnapshot()
        }
    }

    // MARK: - Private

    private var snapshotCacheKey: String {
        "\(coordinates.latitude),\(coordinates.longitude),\(mapSize.width),\(mapSize.height),\(colorScheme)"
    }

    private var placeholderImage: some View {
        Image(asset: Asset.Images.mapBlurred)
            .resizable()
            .scaledToFill()
    }

    private var errorView: some View {
        Button {
            hasError = false
            isLoading = true
            Task {
                await loadSnapshot()
            }
        } label: {
            placeholderImage
                .overlay {
                    VStack(spacing: 0) {
                        Image(systemName: "arrow.clockwise")
                        Text(L10n.actionStaticMapLoad)
                    }
                }
        }
    }

    private func loadSnapshot() async {
        do {
            let image = try await MapSnapshotCache.shared.snapshot(for: coordinates,
                                                                   zoomLevel: zoomLevel,
                                                                   size: mapSize,
                                                                   colorScheme: colorScheme)
            snapshotImage = image
            isLoading = false
            hasError = false
        } catch {
            if !Task.isCancelled {
                snapshotImage = nil
                isLoading = false
                hasError = true
            }
        }
    }

    private static func spanForZoomLevel(_ zoomLevel: Double) -> MKCoordinateSpan {
        let span = 360.0 / pow(2.0, zoomLevel)
        return MKCoordinateSpan(latitudeDelta: span,
                                longitudeDelta: span)
    }
}

// MARK: - Snapshot Cache

/// A simple actor-isolated cache for MKMapSnapshotter results, keyed by coordinates + size + color scheme.
/// This avoids redundant re-renders when the timeline scrolls map tiles in and out of view.
private actor MapSnapshotCache {
    static let shared = MapSnapshotCache()

    private var cache = [String: UIImage]()

    func snapshot(for coordinates: CLLocationCoordinate2D,
                  zoomLevel: Double,
                  size: CGSize,
                  colorScheme: ColorScheme) async throws -> UIImage {
        let key = "\(coordinates.latitude),\(coordinates.longitude),\(size.width),\(size.height),\(colorScheme)"

        if let cached = cache[key] {
            return cached
        }

        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: coordinates,
                                            span: spanForZoomLevel(zoomLevel))
        options.size = CGSize(width: size.width * 2, height: size.height * 2) // @2x resolution
        options.traitCollection = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)

        let snapshotter = MKMapSnapshotter(options: options)
        let result = try await snapshotter.start()
        let image = result.image

        cache[key] = image
        return image
    }

    private func spanForZoomLevel(_ zoomLevel: Double) -> MKCoordinateSpan {
        let span = 360.0 / pow(2.0, zoomLevel)
        return MKCoordinateSpan(latitudeDelta: span,
                                longitudeDelta: span)
    }
}

// MARK: - Previews

struct MapSnapshotView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        MapSnapshotView(coordinates: CLLocationCoordinate2D(latitude: 41.902782,
                                                            longitude: 12.496366),
                        zoomLevel: 15,
                        mapSize: .init(width: 300, height: 200)) {
            Image(systemName: "mappin.circle.fill")
                .padding(.bottom, 35)
        }
    }
}
