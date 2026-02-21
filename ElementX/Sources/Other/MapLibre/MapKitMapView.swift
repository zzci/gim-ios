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

// MARK: - MapAnnotationItem

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let anchorPoint: UnitPoint
    let content: AnyView

    init(coordinate: CLLocationCoordinate2D,
         anchorPoint: UnitPoint = .center,
         @ViewBuilder label: () -> some View) {
        self.coordinate = coordinate
        self.anchorPoint = anchorPoint
        content = AnyView(label())
    }
}

// MARK: - MapKitMapView

struct MapKitMapView: View {
    struct Options {
        /// The final zoom level used when the first user location emits.
        let zoomLevel: Double
        /// The initial zoom level used when the map is first loaded and the user location is not yet available.
        /// In the case of annotations this property is not being used.
        let initialZoomLevel: Double

        /// The initial map center.
        let mapCenter: CLLocationCoordinate2D

        /// Map annotations.
        let annotations: [MapAnnotationItem]

        init(zoomLevel: Double,
             initialZoomLevel: Double,
             mapCenter: CLLocationCoordinate2D,
             annotations: [MapAnnotationItem] = []) {
            self.zoomLevel = zoomLevel
            self.initialZoomLevel = initialZoomLevel
            self.mapCenter = mapCenter
            self.annotations = annotations
        }
    }

    // MARK: - Properties

    let options: Options

    /// Behavior mode of the current user's location, can be hidden, only shown and shown following the user.
    @Binding var showsUserLocationMode: ShowUserLocationMode
    /// Bind view errors if any.
    @Binding var error: MapLibreError?
    /// Coordinate of the center of the map.
    @Binding var mapCenterCoordinate: CLLocationCoordinate2D?
    @Binding var isLocationAuthorized: Bool?
    /// The radius of uncertainty for the location, measured in meters.
    @Binding var geolocationUncertainty: CLLocationAccuracy?

    /// Called when the user pans on the map.
    var userDidPan: (() -> Void)?

    // MARK: - Private State

    @State private var position: MapCameraPosition
    @State private var locationManager = LocationAuthorizationManager()
    @State private var hasReceivedInitialLocation = false
    @State private var isFollowingUser = false
    @Namespace private var mapScope

    // MARK: - Init

    init(options: Options,
         showsUserLocationMode: Binding<ShowUserLocationMode>,
         error: Binding<MapLibreError?>,
         mapCenterCoordinate: Binding<CLLocationCoordinate2D?>,
         isLocationAuthorized: Binding<Bool?>,
         geolocationUncertainty: Binding<CLLocationAccuracy?>,
         userDidPan: (() -> Void)? = nil) {
        self.options = options
        _showsUserLocationMode = showsUserLocationMode
        _error = error
        _mapCenterCoordinate = mapCenterCoordinate
        _isLocationAuthorized = isLocationAuthorized
        _geolocationUncertainty = geolocationUncertainty
        self.userDidPan = userDidPan

        let initialPosition: MapCameraPosition
        if !options.annotations.isEmpty {
            // When annotations are present, center on the map center at the final zoom level.
            initialPosition = .region(MKCoordinateRegion(center: options.mapCenter,
                                                         span: Self.span(for: options.zoomLevel)))
        } else {
            // No annotations: use initialZoomLevel (wide view for picker, or zoom level for view-only).
            initialPosition = .region(MKCoordinateRegion(center: options.mapCenter,
                                                         span: Self.span(for: options.initialZoomLevel)))
        }
        _position = State(initialValue: initialPosition)
    }

    // MARK: - Body

    var body: some View {
        Map(position: $position,
            interactionModes: [.pan, .zoom],
            scope: mapScope) {
            mapContent
        }
        .mapStyle(.standard)
        .mapScope(mapScope)
        .mapControls { }
        .onMapCameraChange(frequency: .onEnd) { context in
            mapCenterCoordinate = context.region.center
        }
        .onChange(of: position.followsUserLocation) { oldValue, newValue in
            // When the user pans the map while following, MapKit stops following
            // and followsUserLocation transitions from true to false.
            if isFollowingUser, oldValue, !newValue {
                userDidPan?()
            }
            isFollowingUser = newValue
        }
        .onChange(of: showsUserLocationMode) { _, newValue in
            applyUserLocationMode(newValue)
        }
        .onChange(of: locationManager.authorizationStatus) { _, newStatus in
            updateAuthorizationBinding(from: newStatus)
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            handleUserLocationUpdate(newLocation)
        }
        .onAppear {
            updateAuthorizationBinding(from: locationManager.authorizationStatus)
            applyUserLocationMode(showsUserLocationMode)
        }
    }

    // MARK: - Map Content

    @MapContentBuilder
    private var mapContent: some MapContent {
        // Render custom annotations
        ForEach(options.annotations) { item in
            Annotation("",
                       coordinate: item.coordinate,
                       anchor: item.anchorPoint) {
                item.content
            }
        }

        // User location
        if showsUserLocationMode != .hide {
            UserAnnotation()
        }
    }

    // MARK: - User Location Mode

    private func applyUserLocationMode(_ mode: ShowUserLocationMode) {
        switch mode {
        case .showAndFollow:
            locationManager.requestWhenInUseAuthorization()
            position = .userLocation(followsHeading: false,
                                     fallback: .region(MKCoordinateRegion(center: options.mapCenter,
                                                                          span: Self.span(for: options.initialZoomLevel))))
        case .show:
            // In show mode with annotations, don't request authorization if not determined.
            if !options.annotations.isEmpty,
               locationManager.authorizationStatus == .notDetermined {
                return
            }
            locationManager.requestWhenInUseAuthorization()
        case .hide:
            break
        }
    }

    // MARK: - Location Updates

    private func handleUserLocationUpdate(_ location: CLLocation?) {
        guard let location else {
            geolocationUncertainty = nil
            return
        }

        // Update geolocation uncertainty
        if location.horizontalAccuracy >= 0 {
            geolocationUncertainty = location.horizontalAccuracy
        } else {
            geolocationUncertainty = nil
        }

        // On first user location, animate to that location at the target zoom level
        // (only when there are no annotations, matching the original behavior).
        if !hasReceivedInitialLocation, options.annotations.isEmpty {
            hasReceivedInitialLocation = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                withAnimation {
                    position = .region(MKCoordinateRegion(center: location.coordinate,
                                                          span: Self.span(for: options.zoomLevel)))
                }
            }
        }
    }

    // MARK: - Authorization

    private func updateAuthorizationBinding(from status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            isLocationAuthorized = false
        case .authorizedAlways, .authorizedWhenInUse:
            isLocationAuthorized = true
        case .notDetermined:
            isLocationAuthorized = nil
        @unknown default:
            break
        }
    }

    // MARK: - Zoom Helpers

    /// Convert a MapLibre-style zoom level to an approximate MKCoordinateSpan.
    ///
    /// MapLibre zoom level 0 = 360 degrees; each level halves the span.
    /// The formula: span = 360 / 2^zoom, clamped to a reasonable minimum.
    private static func span(for zoomLevel: Double) -> MKCoordinateSpan {
        let degrees = 360.0 / pow(2.0, zoomLevel)
        let clamped = max(degrees, 0.0001)
        return MKCoordinateSpan(latitudeDelta: clamped, longitudeDelta: clamped)
    }
}

// MARK: - LocationAuthorizationManager

/// A lightweight location manager that tracks authorization status and user location
/// without requiring a UIViewRepresentable coordinator.
@Observable
private final class LocationAuthorizationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var userLocation: CLLocation?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestWhenInUseAuthorization() {
        guard manager.authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        MXLog.warning("Location manager failed with error: \(error)")
    }
}
