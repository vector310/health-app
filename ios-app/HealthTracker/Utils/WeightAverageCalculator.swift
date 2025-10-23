//
//  WeightAverageCalculator.swift
//  HealthTracker
//
//  Calculates rolling weight averages with confidence scoring
//

import Foundation

struct WeightAverageCalculator {

    /// Result of a rolling average calculation
    struct AverageResult {
        let average: Double?
        let confidence: Double // 0.0 to 1.0
        let readingCount: Int
        let isValid: Bool

        var confidenceLevel: ConfidenceLevel {
            if confidence >= 0.7 { return .high }
            if confidence >= 0.4 { return .medium }
            return .low
        }
    }

    enum ConfidenceLevel {
        case high
        case medium
        case low

        var description: String {
            switch self {
            case .high: return "High confidence"
            case .medium: return "Medium confidence"
            case .low: return "Low confidence"
            }
        }
    }

    /// Calculate 7-day rolling average weight
    /// - Parameters:
    ///   - readings: Array of weight readings
    ///   - targetDate: The date to calculate the average for
    ///   - windowDays: Number of days to look back (default 7)
    /// - Returns: AverageResult with average and confidence score
    static func calculate7DayAverage(
        from readings: [WeightReading],
        targetDate: Date = Date(),
        windowDays: Int = 7
    ) -> AverageResult {
        let calendar = Calendar.current

        // Filter readings within the window
        let windowStart = calendar.date(byAdding: .day, value: -windowDays + 1, to: targetDate) ?? targetDate
        let relevantReadings = readings.filter { reading in
            reading.date >= windowStart && reading.date <= targetDate
        }

        // Minimum 3 readings required for valid average
        guard relevantReadings.count >= 3 else {
            return AverageResult(
                average: nil,
                confidence: 0.0,
                readingCount: relevantReadings.count,
                isValid: false
            )
        }

        // Calculate average
        let sum = relevantReadings.reduce(0.0) { $0 + $1.weight }
        let average = sum / Double(relevantReadings.count)

        // Calculate confidence score
        let confidence = Double(relevantReadings.count) / Double(windowDays)

        return AverageResult(
            average: average,
            confidence: confidence,
            readingCount: relevantReadings.count,
            isValid: true
        )
    }

    /// Calculate week-over-week weight change
    /// - Parameters:
    ///   - currentWeekReadings: Readings from the current week
    ///   - previousWeekReadings: Readings from the previous week
    /// - Returns: The change in pounds (positive = gained, negative = lost)
    static func calculateWeekOverWeekChange(
        currentWeekReadings: [WeightReading],
        previousWeekReadings: [WeightReading]
    ) -> Double? {
        let currentAvg = calculate7DayAverage(from: currentWeekReadings)
        let previousAvg = calculate7DayAverage(from: previousWeekReadings)

        guard let current = currentAvg.average,
              let previous = previousAvg.average,
              currentAvg.isValid && previousAvg.isValid else {
            return nil
        }

        return current - previous
    }

    /// Format weight change for display
    /// - Parameter change: The weight change in pounds
    /// - Returns: Formatted string like "+1.2 lbs" or "-0.8 lbs"
    static func formatWeightChange(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return String(format: "\(sign)%.1f lbs", change)
    }

    /// Format weight for display
    /// - Parameter weight: The weight in pounds
    /// - Returns: Formatted string like "185.4 lbs"
    static func formatWeight(_ weight: Double) -> String {
        return String(format: "%.1f lbs", weight)
    }
}
