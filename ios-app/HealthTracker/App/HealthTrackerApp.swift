//
//  HealthTrackerApp.swift
//  HealthTracker
//
//  Main app entry point with environment setup
//

import SwiftUI

@main
struct HealthTrackerApp: App {

    // Shared services
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var apiService = APIService()
    @StateObject private var cacheManager = CacheManager()

    // App state
    @State private var isOnboardingComplete = false

    init() {
        // Configure appearance
        configureAppearance()

        // Check if onboarding is complete
        _isOnboardingComplete = State(initialValue: KeychainManager.shared.isConfigured)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isOnboardingComplete {
                    ContentView()
                        .environmentObject(healthKitManager)
                        .environmentObject(apiService)
                        .environmentObject(cacheManager)
                } else {
                    OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                        .environmentObject(healthKitManager)
                        .environmentObject(apiService)
                }
            }
            .task {
                await initializeApp()
            }
        }
    }

    // MARK: - Initialization

    private func initializeApp() async {
        // Configure API service if credentials exist
        if let serverURL = KeychainManager.shared.serverURL,
           let apiKey = KeychainManager.shared.apiKey {
            apiService.configure(baseURL: serverURL, apiKey: apiKey)

            // Try to connect to server
            try? await apiService.healthCheck()
        }

        // Check HealthKit authorization status
        if healthKitManager.checkAuthorization() {
            healthKitManager.isAuthorized = true
        }
    }

    // MARK: - Appearance

    private func configureAppearance() {
        // Use system defaults for iOS 18 Liquid Glass design
        // Custom configurations can be added here if needed
    }
}
