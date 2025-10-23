//
//  OnboardingView.swift
//  HealthTracker
//
//  First-run onboarding for API setup and HealthKit permissions
//

import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var apiService: APIService

    @Binding var isOnboardingComplete: Bool

    @State private var currentStep = 0
    @State private var serverURL = ""
    @State private var apiKey = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // App Icon/Logo
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)
                        .padding(.bottom, 8)

                    // Title
                    Text("Health Tracker")
                        .font(.largeTitle.bold())

                    Text("Track your fitness journey with AI-powered insights")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer()

                    // Step indicator
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(index == currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 16)

                    // Content based on step
                    Group {
                        switch currentStep {
                        case 0:
                            welcomeStep
                        case 1:
                            apiConfigStep
                        case 2:
                            healthKitStep
                        default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Weekly Tracking", description: "Monitor steps, calories, protein, and weight")
                FeatureRow(icon: "target", title: "Smart Goals", description: "Set targets and track progress automatically")
                FeatureRow(icon: "brain.head.profile", title: "AI Analysis", description: "Get insights from Claude about your health trends")
            }

            Button(action: { currentStep = 1 }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
    }

    private var apiConfigStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Connect to Your Server")
                    .font(.title2.bold())

                Text("Enter your MCP server URL and API key to sync your health data.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Server URL")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("https://health-tracker-mcp.workers.dev", text: $serverURL)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("API Key")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SecureField("Enter your API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Button(action: testConnection) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Continue")
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(serverURL.isEmpty || apiKey.isEmpty ? Color.gray : Color.blue)
            .cornerRadius(12)
            .disabled(serverURL.isEmpty || apiKey.isEmpty || isLoading)
        }
    }

    private var healthKitStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("HealthKit Access")
                    .font(.title2.bold())

                Text("We need permission to read your health data from Apple Health.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 12) {
                PermissionRow(icon: "figure.walk", title: "Steps", description: "Daily step count")
                PermissionRow(icon: "fork.knife", title: "Nutrition", description: "Calories and protein intake")
                PermissionRow(icon: "figure.run", title: "Workouts", description: "Cardio calories burned")
                PermissionRow(icon: "scalemass", title: "Body Metrics", description: "Weight and body composition")
            }

            Button(action: requestHealthKitPermission) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Grant Access")
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .disabled(isLoading)
        }
    }

    // MARK: - Actions

    private func testConnection() {
        isLoading = true
        errorMessage = nil

        // Save to keychain
        KeychainManager.shared.serverURL = serverURL
        KeychainManager.shared.apiKey = apiKey

        // Configure API service
        apiService.configure(baseURL: serverURL, apiKey: apiKey)

        // Test connection
        Task {
            do {
                let success = try await apiService.healthCheck()
                await MainActor.run {
                    isLoading = false
                    if success {
                        currentStep = 2
                    } else {
                        errorMessage = "Could not connect to server. Please check your URL and API key."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func requestHealthKitPermission() {
        isLoading = true

        Task {
            do {
                try await healthKitManager.requestAuthorization()
                await MainActor.run {
                    isLoading = false
                    completeOnboarding()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func completeOnboarding() {
        withAnimation {
            isOnboardingComplete = true
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
        .environmentObject(HealthKitManager())
        .environmentObject(APIService())
}
