//
//  SettingsView.swift
//  HealthTracker
//
//  Settings and configuration
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var cacheManager: CacheManager

    @State private var serverURL = KeychainManager.shared.serverURL ?? ""
    @State private var apiKey = ""
    @State private var showingAPIKeyField = false

    @State private var showingProfileEditor = false
    @State private var showingAbout = false

    @State private var isTestingConnection = false
    @State private var connectionTestResult: String?

    var body: some View {
        NavigationStack {
            Form {
                // Server Configuration
                Section {
                    HStack {
                        Text("Server URL")
                        Spacer()
                        Text(serverURL.isEmpty ? "Not set" : maskURL(serverURL))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if showingAPIKeyField {
                        SecureField("Enter API Key", text: $apiKey)

                        Button("Save API Key") {
                            saveAPIKey()
                        }
                        .disabled(apiKey.isEmpty)
                    } else {
                        Button("Update API Key") {
                            showingAPIKeyField = true
                        }
                    }

                    Button(action: testConnection) {
                        HStack {
                            Text("Test Connection")
                            Spacer()
                            if isTestingConnection {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(serverURL.isEmpty || isTestingConnection)

                    if let result = connectionTestResult {
                        Text(result)
                            .font(.caption)
                            .foregroundColor(result.contains("Success") ? .green : .red)
                    }
                } header: {
                    Text("Server Configuration")
                } footer: {
                    Text("Your MCP server URL and API key for syncing health data")
                }

                // HealthKit
                Section {
                    HStack {
                        Text("HealthKit Access")
                        Spacer()
                        if healthKitManager.isAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Button("Grant Access") {
                                requestHealthKitAccess()
                            }
                        }
                    }

                    Button("Open Health App") {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    }
                } header: {
                    Text("Health Data")
                } footer: {
                    Text("Permissions for reading steps, calories, protein, weight, and body composition")
                }

                // User Profile
                Section {
                    Button("Edit Profile") {
                        showingProfileEditor = true
                    }
                } header: {
                    Text("Profile")
                } footer: {
                    Text("Height, age, and sex for BMR calculations")
                }

                // Sync Status
                Section {
                    if let lastSync = apiService.lastSyncDate {
                        HStack {
                            Text("Last Sync")
                            Spacer()
                            Text(lastSync, style: .relative)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if apiService.isConnected {
                        HStack {
                            Text("Status")
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                                Text("Connected")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button("Clear Cache") {
                        clearCache()
                    }
                } header: {
                    Text("Data")
                }

                // About
                Section {
                    Button("About") {
                        showingAbout = true
                    }

                    Link("View on GitHub", destination: URL(string: "https://github.com/your-repo/health-tracker")!)

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("App Info")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingProfileEditor) {
                ProfileEditorView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }

    // MARK: - Actions

    private func saveAPIKey() {
        KeychainManager.shared.apiKey = apiKey

        // Reconfigure API service
        if let url = KeychainManager.shared.serverURL {
            apiService.configure(baseURL: url, apiKey: apiKey)
        }

        showingAPIKeyField = false
        apiKey = ""

        // Show success feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil

        Task {
            do {
                let success = try await apiService.healthCheck()
                await MainActor.run {
                    isTestingConnection = false
                    connectionTestResult = success ? "✓ Connection successful" : "✗ Connection failed"
                }
            } catch {
                await MainActor.run {
                    isTestingConnection = false
                    connectionTestResult = "✗ Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func requestHealthKitAccess() {
        Task {
            do {
                try await healthKitManager.requestAuthorization()
            } catch {
                print("HealthKit authorization failed: \(error)")
            }
        }
    }

    private func clearCache() {
        cacheManager.clearAll()

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Helpers

    private func maskURL(_ url: String) -> String {
        guard let host = URL(string: url)?.host else { return url }
        return host
    }
}

// MARK: - Profile Editor

struct ProfileEditorView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var cacheManager: CacheManager

    @State private var heightFeet: Int
    @State private var heightInches: Int
    @State private var age: Int
    @State private var sex: CalorieBalanceCalculator.UserProfile.Sex

    init() {
        if let profile = CacheManager().getCachedUserProfile() {
            _heightFeet = State(initialValue: Int(profile.heightCm / 30.48))
            _heightInches = State(initialValue: Int(profile.heightCm.truncatingRemainder(dividingBy: 30.48) / 2.54))
            _age = State(initialValue: profile.age)
            _sex = State(initialValue: profile.sex)
        } else {
            _heightFeet = State(initialValue: 5)
            _heightInches = State(initialValue: 10)
            _age = State(initialValue: 30)
            _sex = State(initialValue: .male)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Sex", selection: $sex) {
                        Text("Male").tag(CalorieBalanceCalculator.UserProfile.Sex.male)
                        Text("Female").tag(CalorieBalanceCalculator.UserProfile.Sex.female)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Sex")
                }

                Section {
                    Stepper("Age: \(age)", value: $age, in: 18...100)
                } header: {
                    Text("Age")
                }

                Section {
                    HStack {
                        Stepper("Feet: \(heightFeet)", value: $heightFeet, in: 4...7)
                    }

                    HStack {
                        Stepper("Inches: \(heightInches)", value: $heightInches, in: 0...11)
                    }

                    HStack {
                        Text("Total Height")
                        Spacer()
                        Text("\(heightFeet)' \(heightInches)\" (\(String(format: "%.1f", totalHeightCm)) cm)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Height")
                } footer: {
                    Text("Used for BMR (Basal Metabolic Rate) calculations")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                }
            }
        }
    }

    private var totalHeightCm: Double {
        Double(heightFeet) * 30.48 + Double(heightInches) * 2.54
    }

    private func saveProfile() {
        // Get current weight from cache or default
        let profile = CalorieBalanceCalculator.UserProfile(
            weightKg: 80.0, // This should come from recent weight readings
            heightCm: totalHeightCm,
            age: age,
            sex: sex
        )

        cacheManager.cacheUserProfile(profile)
        dismiss()
    }
}

// MARK: - About

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)
                        .padding(.top, 40)

                    Text("Health Tracker")
                        .font(.title.bold())

                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Divider()
                        .padding(.horizontal, 40)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.headline)

                        Text("A personal health tracking app that aggregates fitness and body composition data from Apple Health to provide weekly summaries for PT check-ins and long-term trend analysis.")
                            .foregroundStyle(.secondary)

                        Text("Features")
                            .font(.headline)
                            .padding(.top, 8)

                        FeatureListItem(icon: "figure.walk", text: "Track steps, calories, protein, and cardio")
                        FeatureListItem(icon: "scalemass", text: "Monitor weight and body composition trends")
                        FeatureListItem(icon: "target", text: "Set weekly targets and phases")
                        FeatureListItem(icon: "chart.line.uptrend.xyaxis", text: "Visualize long-term progress")
                        FeatureListItem(icon: "brain.head.profile", text: "AI-powered analysis via Claude")

                        Text("Built with")
                            .font(.headline)
                            .padding(.top, 8)

                        FeatureListItem(icon: "heart.text.square", text: "Apple HealthKit")
                        FeatureListItem(icon: "cloud", text: "Cloudflare Workers & D1")
                        FeatureListItem(icon: "sparkles", text: "Claude AI (MCP)")
                    }
                    .padding(.horizontal, 32)

                    Divider()
                        .padding(.horizontal, 40)

                    Text("© 2024 Health Tracker\nBuilt with Claude Code")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureListItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(HealthKitManager())
        .environmentObject(APIService())
        .environmentObject(CacheManager())
}
