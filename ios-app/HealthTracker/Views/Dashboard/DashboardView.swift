//
//  DashboardView.swift
//  HealthTracker
//
//  Main dashboard with current week metrics
//

import SwiftUI

struct DashboardView: View {

    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var cacheManager: CacheManager

    @StateObject private var viewModel: DashboardViewModel

    @State private var showingCheckIn = false
    @State private var showingTargetEditor = false

    init() {
        // Note: In actual implementation, inject dependencies properly
        // This is a simplified version for demonstration
        _viewModel = StateObject(wrappedValue: DashboardViewModel(
            healthKitManager: HealthKitManager(),
            apiService: APIService(),
            cacheManager: CacheManager()
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Week Header
                        weekHeaderView

                        // Check-in banner (Sunday mornings)
                        if viewModel.isCheckInTime {
                            checkInBanner
                        }

                        // Metrics Grid
                        metricsGrid

                        // Quick Actions
                        quickActions
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refresh()
                }

                // Loading overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.blue)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .task {
                // Inject environment objects into ViewModel
                viewModel.healthKitManager = healthKitManager
                viewModel.apiService = apiService
                viewModel.cacheManager = cacheManager

                // Load data
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingCheckIn) {
                CheckInView(week: viewModel.currentWeek)
            }
            .sheet(isPresented: $showingTargetEditor) {
                TargetEditorView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Week Header

    private var weekHeaderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let week = viewModel.currentWeek {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Week")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(week.dateRangeString)
                            .font(.title2.bold())

                        Text("Day \(viewModel.daysIntoWeek) of 7 • \(week.phase.displayName) Phase")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Phase badge
                    Text(week.phase.displayName.uppercased())
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(phaseColor(week.phase).opacity(0.2))
                        .foregroundColor(phaseColor(week.phase))
                        .cornerRadius(8)
                }
            } else {
                Text("Loading...")
                    .font(.title2.bold())
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Check-In Banner

    private var checkInBanner: some View {
        Button(action: { showingCheckIn = true }) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Check-In Ready")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Tap to copy metrics for your PT")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.green.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.green.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        VStack(spacing: 16) {
            // Steps
            if let week = viewModel.currentWeek {
                MetricCardView(
                    title: "Steps",
                    value: formatNumber(viewModel.runningSteps),
                    target: "/ \(formatNumber(week.targetSteps))",
                    progress: Double(viewModel.runningSteps) / Double(week.targetSteps),
                    icon: "figure.walk",
                    copyValue: formatNumber(viewModel.runningSteps)
                )

                // Calories + Protein
                MetricCardView(
                    title: "Calories + Protein",
                    value: "\(formatNumber(viewModel.runningCalories)) / \(formatNumber(viewModel.runningProtein))g",
                    target: "/ \(formatNumber(week.targetCalories)) / \(formatNumber(week.targetProtein))g",
                    progress: (Double(viewModel.runningCalories) / Double(week.targetCalories) + Double(viewModel.runningProtein) / Double(week.targetProtein)) / 2.0,
                    icon: "fork.knife",
                    copyValue: "\(formatNumber(viewModel.runningCalories)) kcal / \(formatNumber(viewModel.runningProtein)) g"
                )

                // Cardio
                MetricCardView(
                    title: "Cardio Calories",
                    value: "\(formatNumber(viewModel.runningCardio)) kcal",
                    target: "/ \(formatNumber(week.targetCardio)) kcal",
                    progress: Double(viewModel.runningCardio) / Double(week.targetCardio),
                    icon: "flame",
                    copyValue: "\(formatNumber(viewModel.runningCardio)) kcal"
                )

                // Weight
                if let avgWeight = viewModel.sevenDayAverage {
                    MetricCardView(
                        title: "7-Day Avg Weight",
                        value: String(format: "%.1f lbs", avgWeight),
                        target: week.weekOverWeekWeightChange != nil ? "\(week.weekOverWeekWeightChange! >= 0 ? "+" : "")\(String(format: "%.1f", week.weekOverWeekWeightChange!)) lbs WoW" : nil,
                        progress: nil,
                        icon: "scalemass",
                        copyValue: String(format: "%.1f", avgWeight)
                    )
                }

                // Body Composition
                if let bodyFat = week.bodyFatPercentage {
                    HStack(spacing: 16) {
                        // Body Fat
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Body Fat")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(String(format: "%.1f%%", bodyFat))
                                .font(.title3.bold())

                            if let change = week.bodyFatChange {
                                Text("\(change >= 0 ? "+" : "")\(String(format: "%.1f%%", change))")
                                    .font(.caption)
                                    .foregroundColor(change > 0 ? .red : .green)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)

                        // Muscle Mass
                        if let muscleMass = week.muscleMassPercentage {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Muscle Mass")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(String(format: "%.1f%%", muscleMass))
                                    .font(.title3.bold())

                                if let change = week.muscleMassChange {
                                    Text("\(change >= 0 ? "+" : "")\(String(format: "%.1f%%", change))")
                                        .font(.caption)
                                        .foregroundColor(change > 0 ? .green : .red)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(spacing: 12) {
            Button(action: { showingTargetEditor = true }) {
                HStack {
                    Image(systemName: "target")
                    Text("Edit This Week's Targets")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            .foregroundStyle(.primary)

            if let lastSync = viewModel.lastSyncDate {
                Text("Last synced: \(lastSync, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Helpers

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private func phaseColor(_ phase: Phase) -> Color {
        switch phase {
        case .cut:
            return .red
        case .maintenance:
            return .yellow
        case .bulk:
            return .green
        }
    }
}

// MARK: - Target Editor

struct TargetEditorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DashboardViewModel

    @State private var calories: String
    @State private var protein: String
    @State private var steps: String
    @State private var cardio: String
    @State private var selectedPhase: Phase

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
        _calories = State(initialValue: "\(viewModel.currentWeek?.targetCalories ?? 14000)")
        _protein = State(initialValue: "\(viewModel.currentWeek?.targetProtein ?? 1000)")
        _steps = State(initialValue: "\(viewModel.currentWeek?.targetSteps ?? 70000)")
        _cardio = State(initialValue: "\(viewModel.currentWeek?.targetCardio ?? 2000)")
        _selectedPhase = State(initialValue: viewModel.currentWeek?.phase ?? .maintenance)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weekly Targets") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("14000", text: $calories)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("1000", text: $protein)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Steps")
                        Spacer()
                        TextField("70000", text: $steps)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Cardio (kcal)")
                        Spacer()
                        TextField("2000", text: $cardio)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Phase") {
                    Picker("Training Phase", selection: $selectedPhase) {
                        ForEach(Phase.allCases, id: \.self) { phase in
                            Text(phase.displayName).tag(phase)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Edit Targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTargets()
                    }
                }
            }
        }
    }

    private func saveTargets() {
        guard let cal = Int(calories),
              let pro = Int(protein),
              let stp = Int(steps),
              let crd = Int(cardio) else {
            return
        }

        Task {
            await viewModel.updateTargets(
                calories: cal,
                protein: pro,
                steps: stp,
                cardio: crd,
                phase: selectedPhase
            )
            dismiss()
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(HealthKitManager())
        .environmentObject(APIService())
        .environmentObject(CacheManager())
}
