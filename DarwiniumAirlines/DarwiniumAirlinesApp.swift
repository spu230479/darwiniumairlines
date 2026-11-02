//
//  DarwiniumAirlinesApp.swift
//  Darwinium Airlines
//

import SwiftUI
import CoreLocation

@main
struct DarwiniumAirlinesApp: App {
    @StateObject private var app = AppState()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Web: the injected profiling script ran dwn_ns.load() on page load.
        // iOS: start the Darwinium SDK as soon as the app launches so it can
        // gather device, network, touch and sensor signals before the first API call.
        DwnProfiler.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .preferredColorScheme(.dark)
                .onAppear { LocationPermission.shared.requestIfNeeded() }
        }
    }
}

/// Web injection had `dwn_ns.geo_location_enabled = true`. The SDK does not
/// prompt by itself (ask_location_permission = false), so the app asks.
final class LocationPermission: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermission()
    private let manager = CLLocationManager()

    func requestIfNeeded() {
        manager.delegate = self
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
}
