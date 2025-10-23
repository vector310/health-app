//
//  CheckInView.swift
//  HealthTracker
//
//  Sunday morning check-in interface with tap-to-copy metrics
//

import SwiftUI

struct CheckInView: View {

    @Environment(\.dismiss) var dismiss

    let week: WeekRecord?

    @State private var copiedItems: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green.gradient)

                        Text("Weekly Check-In")
                            .font(.title.bold())

                        if let week = week {
                            Text(week.dateRangeString)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text("Tap any metric to copy")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 4)
                    }
                    .padding(.top)

                    Divider()

                    // Metrics
                    if let week = week {
                        VStack(spacing: 16) {
                            CheckInMetricRow(
                                title: "Steps",
                                value: formatNumber(week.totalSteps ?? 0),
                                copyValue: formatNumber(week.totalSteps ?? 0),
                                icon: "figure.walk",
                                isCopied: copiedItems.contains("steps"),
                                onCopy: { copyMetric("steps", value: formatNumber(week.totalSteps ?? 0)) }
                            )

                            CheckInMetricRow(
                                title: "Calories + Protein",
                                value: "\(formatNumber(week.totalCalories ?? 0)) kcal / \(formatNumber(week.totalProtein ?? 0)) g",
                                copyValue: "\(formatNumber(week.totalCalories ?? 0)) kcal / \(formatNumber(week.totalProtein ?? 0)) g",
                                icon: "fork.knife",
                                isCopied: copiedItems.contains("nutrition"),
                                onCopy: { copyMetric("nutrition", value: "\(formatNumber(week.totalCalories ?? 0)) kcal / \(formatNumber(week.totalProtein ?? 0)) g") }
                            )

                            CheckInMetricRow(
                                title: "Cardio",
                                value: "\(formatNumber(week.totalCardioCalories ?? 0)) kcal",
                                copyValue: "\(formatNumber(week.totalCardioCalories ?? 0)) kcal",
                                icon: "flame",
                                isCopied: copiedItems.contains("cardio"),
                                onCopy: { copyMetric("cardio", value: "\(formatNumber(week.totalCardioCalories ?? 0)) kcal") }
                            )

                            if let weight = week.averageWeight {
                                CheckInMetricRow(
                                    title: "Weight (7-day avg)",
                                    value: String(format: "%.1f lbs", weight),
                                    copyValue: String(format: "%.1f", weight),
                                    icon: "scalemass",
                                    isCopied: copiedItems.contains("weight"),
                                    onCopy: { copyMetric("weight", value: String(format: "%.1f", weight)) }
                                )
                            }

                            if let bodyFat = week.bodyFatPercentage {
                                CheckInMetricRow(
                                    title: "Body Fat %",
                                    value: String(format: "%.1f%%", bodyFat),
                                    copyValue: String(format: "%.1f", bodyFat),
                                    icon: "chart.pie",
                                    isCopied: copiedItems.contains("bodyfat"),
                                    onCopy: { copyMetric("bodyfat", value: String(format: "%.1f", bodyFat)) }
                                )
                            }

                            if let muscleMass = week.muscleMassPercentage {
                                CheckInMetricRow(
                                    title: "Muscle Mass %",
                                    value: String(format: "%.1f%%", muscleMass),
                                    copyValue: String(format: "%.1f", muscleMass),
                                    icon: "figure.arms.open",
                                    isCopied: copiedItems.contains("muscle"),
                                    onCopy: { copyMetric("muscle", value: String(format: "%.1f", muscleMass)) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Copy All Button
                    if let week = week {
                        Button(action: { copyAll(week: week) }) {
                            Label("Copy All Metrics", systemImage: "doc.on.doc")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Check-In")
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

    // MARK: - Actions

    private func copyMetric(_ id: String, value: String) {
        UIPasteboard.general.string = value

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Mark as copied
        withAnimation {
            copiedItems.insert(id)
        }

        // Remove after delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                withAnimation {
                    copiedItems.remove(id)
                }
            }
        }
    }

    private func copyAll(week: WeekRecord) {
        var text = ""
        text += "Steps: \(formatNumber(week.totalSteps ?? 0))\n"
        text += "Calories + Protein: \(formatNumber(week.totalCalories ?? 0)) kcal / \(formatNumber(week.totalProtein ?? 0)) g\n"
        text += "Cardio: \(formatNumber(week.totalCardioCalories ?? 0)) kcal\n"

        if let weight = week.averageWeight {
            text += "Weight: \(String(format: "%.1f lbs", weight))\n"
        }

        if let bodyFat = week.bodyFatPercentage {
            text += "Body Fat: \(String(format: "%.1f%%", bodyFat))\n"
        }

        if let muscleMass = week.muscleMassPercentage {
            text += "Muscle Mass: \(String(format: "%.1f%%", muscleMass))\n"
        }

        UIPasteboard.general.string = text

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Mark all as copied
        withAnimation {
            copiedItems = ["steps", "nutrition", "cardio", "weight", "bodyfat", "muscle"]
        }

        // Clear after delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation {
                    copiedItems.removeAll()
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Check-In Metric Row

struct CheckInMetricRow: View {
    let title: String
    let value: String
    let copyValue: String
    let icon: String
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        Button(action: onCopy) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 40)

                // Title & Value
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                }

                Spacer()

                // Copy indicator
                if isCopied {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CheckInView(week: WeekRecord(
        startDate: Date(),
        endDate: Date(),
        targetCalories: 14000,
        targetProtein: 1000,
        targetSteps: 70000,
        targetCardio: 2000,
        phase: .cut,
        totalSteps: 52431,
        totalCalories: 10234,
        totalProtein: 687,
        totalCardioCalories: 1234,
        averageWeight: 185.4,
        weekOverWeekWeightChange: -1.2,
        bodyFatPercentage: 18.2,
        bodyFatChange: -0.5,
        muscleMassPercentage: 42.6,
        muscleMassChange: 0.3,
        isComplete: false
    ))
}
