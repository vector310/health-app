//
//  MetricCardView.swift
//  HealthTracker
//
//  Reusable metric card with tap-to-copy functionality
//

import SwiftUI

struct MetricCardView: View {

    let title: String
    let value: String
    let target: String?
    let progress: Double?
    let icon: String
    let copyValue: String

    @State private var showCopiedCheck = false

    var body: some View {
        Button(action: copyToClipboard) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.blue)

                    Spacer()

                    if showCopiedCheck {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                // Value
                Text(value)
                    .font(.title.bold())
                    .foregroundStyle(.primary)

                // Title & Target
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let target = target {
                        Text(target)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                // Progress bar
                if let progress = progress {
                    ProgressView(value: min(progress, 1.0))
                        .tint(progressColor(for: progress))
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func copyToClipboard() {
        UIPasteboard.general.string = copyValue

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Show checkmark
        withAnimation(.spring(response: 0.3)) {
            showCopiedCheck = true
        }

        // Hide checkmark after delay
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            await MainActor.run {
                withAnimation {
                    showCopiedCheck = false
                }
            }
        }
    }

    // MARK: - Helpers

    private func progressColor(for progress: Double) -> Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.75 {
            return .blue
        } else if progress >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MetricCardView(
            title: "Steps",
            value: "52,431",
            target: "/ 70,000",
            progress: 0.75,
            icon: "figure.walk",
            copyValue: "52,431"
        )

        MetricCardView(
            title: "Calories + Protein",
            value: "10,234 / 687g",
            target: "/ 14,000 / 1,000g",
            progress: 0.73,
            icon: "fork.knife",
            copyValue: "10,234 kcal / 687 g"
        )

        MetricCardView(
            title: "7-Day Avg Weight",
            value: "185.4 lbs",
            target: nil,
            progress: nil,
            icon: "scalemass",
            copyValue: "185.4"
        )
    }
    .padding()
}
