//
//  HistoryView.swift
//  HealthTracker
//
//  Historical weeks list with infinite scroll
//

import SwiftUI

struct HistoryView: View {

    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var cacheManager: CacheManager

    @StateObject private var viewModel: HistoryViewModel

    @State private var selectedWeek: WeekRecord?

    init() {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(
            apiService: APIService(),
            cacheManager: CacheManager()
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.weeks.isEmpty {
                    ProgressView()
                } else if viewModel.weeks.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.weeks) { week in
                                WeekCardView(week: week)
                                    .onTapGesture {
                                        selectedWeek = week
                                    }
                                    .onAppear {
                                        // Load more when near the end
                                        if week.id == viewModel.weeks.last?.id {
                                            Task {
                                                await viewModel.loadMoreWeeks()
                                            }
                                        }
                                    }
                            }

                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("History")
            .task {
                viewModel.apiService = apiService
                viewModel.cacheManager = cacheManager
                await viewModel.loadWeeks()
            }
            .sheet(item: $selectedWeek) { week in
                WeekDetailView(week: week)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            Text("No History Yet")
                .font(.title2.bold())

            Text("Complete your first week to see it here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Week Card

struct WeekCardView: View {
    let week: WeekRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(week.dateRangeString)
                        .font(.headline)

                    Text(week.phase.displayName + " Phase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Phase badge
                Text(week.phase.displayName.uppercased())
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(phaseColor(week.phase).opacity(0.2))
                    .foregroundColor(phaseColor(week.phase))
                    .cornerRadius(6)
            }

            Divider()

            // Metrics Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricPill(
                    title: "Steps",
                    value: formatNumber(week.totalSteps ?? 0),
                    target: formatNumber(week.targetSteps),
                    isGoalMet: (week.totalSteps ?? 0) >= week.targetSteps
                )

                MetricPill(
                    title: "Calories",
                    value: formatNumber(week.totalCalories ?? 0),
                    target: formatNumber(week.targetCalories),
                    isGoalMet: (week.totalCalories ?? 0) >= week.targetCalories
                )

                MetricPill(
                    title: "Protein",
                    value: "\(formatNumber(week.totalProtein ?? 0))g",
                    target: "\(formatNumber(week.targetProtein))g",
                    isGoalMet: (week.totalProtein ?? 0) >= week.targetProtein
                )

                MetricPill(
                    title: "Cardio",
                    value: "\(formatNumber(week.totalCardioCalories ?? 0))",
                    target: "\(formatNumber(week.targetCardio))",
                    isGoalMet: (week.totalCardioCalories ?? 0) >= week.targetCardio
                )
            }

            // Weight info
            if let weight = week.averageWeight {
                HStack {
                    Image(systemName: "scalemass")
                        .foregroundStyle(.blue)

                    Text("Avg: \(String(format: "%.1f lbs", weight))")
                        .font(.subheadline)

                    if let change = week.weekOverWeekWeightChange {
                        Text("(\(change >= 0 ? "+" : "")\(String(format: "%.1f", change)) lbs)")
                            .font(.caption)
                            .foregroundColor(change > 0 ? .orange : .green)
                    }

                    Spacer()

                    if week.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func phaseColor(_ phase: Phase) -> Color {
        switch phase {
        case .cut: return .red
        case .maintenance: return .yellow
        case .bulk: return .green
        }
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Metric Pill

struct MetricPill: View {
    let title: String
    let value: String
    let target: String
    let isGoalMet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if isGoalMet {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

            Text(value)
                .font(.subheadline.bold())

            Text("/ \(target)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(8)
        .background(.thinMaterial)
        .cornerRadius(8)
    }
}

// MARK: - Week Detail

struct WeekDetailView: View {
    @Environment(\.dismiss) var dismiss
    let week: WeekRecord

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Week Summary")
                            .font(.title2.bold())

                        Text(week.dateRangeString)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("\(week.phase.displayName) Phase")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(phaseColor(week.phase).opacity(0.2))
                            .foregroundColor(phaseColor(week.phase))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    // Detailed Metrics
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Metrics")
                            .font(.title3.bold())

                        DetailMetricRow(
                            title: "Steps",
                            actual: formatNumber(week.totalSteps ?? 0),
                            target: formatNumber(week.targetSteps),
                            icon: "figure.walk"
                        )

                        DetailMetricRow(
                            title: "Calories",
                            actual: formatNumber(week.totalCalories ?? 0),
                            target: formatNumber(week.targetCalories),
                            icon: "flame"
                        )

                        DetailMetricRow(
                            title: "Protein",
                            actual: "\(formatNumber(week.totalProtein ?? 0))g",
                            target: "\(formatNumber(week.targetProtein))g",
                            icon: "fork.knife"
                        )

                        DetailMetricRow(
                            title: "Cardio",
                            actual: "\(formatNumber(week.totalCardioCalories ?? 0)) kcal",
                            target: "\(formatNumber(week.targetCardio)) kcal",
                            icon: "figure.run"
                        )
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    // Body Composition
                    if week.averageWeight != nil || week.bodyFatPercentage != nil {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Body Composition")
                                .font(.title3.bold())

                            if let weight = week.averageWeight {
                                HStack {
                                    Text("Weight (7-day avg)")
                                    Spacer()
                                    Text(String(format: "%.1f lbs", weight))
                                        .bold()
                                }
                            }

                            if let bodyFat = week.bodyFatPercentage {
                                HStack {
                                    Text("Body Fat")
                                    Spacer()
                                    Text(String(format: "%.1f%%", bodyFat))
                                        .bold()
                                }
                            }

                            if let muscleMass = week.muscleMassPercentage {
                                HStack {
                                    Text("Muscle Mass")
                                    Spacer()
                                    Text(String(format: "%.1f%%", muscleMass))
                                        .bold()
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
            .navigationTitle("Week Details")
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

    private func phaseColor(_ phase: Phase) -> Color {
        switch phase {
        case .cut: return .red
        case .maintenance: return .yellow
        case .bulk: return .green
        }
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

struct DetailMetricRow: View {
    let title: String
    let actual: String
    let target: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text("Target: \(target)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(actual)
                .font(.headline)
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(APIService())
        .environmentObject(CacheManager())
}
