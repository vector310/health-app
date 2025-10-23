//
//  WeekRecord.swift
//  HealthTracker
//
//  Model for a complete week's health data and targets
//

import Foundation

struct WeekRecord: Codable, Identifiable {
    let id: UUID
    let startDate: Date // Sunday
    let endDate: Date   // Saturday

    // Targets
    var targetCalories: Int
    var targetProtein: Int
    var targetSteps: Int
    var targetCardio: Int
    var phase: Phase

    // Actuals (aggregated at week end)
    var totalSteps: Int?
    var totalCalories: Int?
    var totalProtein: Int?
    var totalCardioCalories: Int?
    var averageWeight: Double?
    var weekOverWeekWeightChange: Double?

    // Body composition (end of week values)
    var bodyFatPercentage: Double?
    var bodyFatChange: Double?
    var muscleMassPercentage: Double?
    var muscleMassChange: Double?

    // Metadata
    var isComplete: Bool
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        targetCalories: Int = 2000,
        targetProtein: Int = 150,
        targetSteps: Int = 70000,
        targetCardio: Int = 2000,
        phase: Phase = .maintenance,
        totalSteps: Int? = nil,
        totalCalories: Int? = nil,
        totalProtein: Int? = nil,
        totalCardioCalories: Int? = nil,
        averageWeight: Double? = nil,
        weekOverWeekWeightChange: Double? = nil,
        bodyFatPercentage: Double? = nil,
        bodyFatChange: Double? = nil,
        muscleMassPercentage: Double? = nil,
        muscleMassChange: Double? = nil,
        isComplete: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.targetCalories = targetCalories
        self.targetProtein = targetProtein
        self.targetSteps = targetSteps
        self.targetCardio = targetCardio
        self.phase = phase
        self.totalSteps = totalSteps
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalCardioCalories = totalCardioCalories
        self.averageWeight = averageWeight
        self.weekOverWeekWeightChange = weekOverWeekWeightChange
        self.bodyFatPercentage = bodyFatPercentage
        self.bodyFatChange = bodyFatChange
        self.muscleMassPercentage = muscleMassPercentage
        self.muscleMassChange = muscleMassChange
        self.isComplete = isComplete
        self.completedAt = completedAt
    }
}

// MARK: - Computed Properties

extension WeekRecord {
    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    var isCurrentWeek: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    var stepsProgress: Double? {
        guard let totalSteps = totalSteps else { return nil }
        return Double(totalSteps) / Double(targetSteps)
    }

    var caloriesProgress: Double? {
        guard let totalCalories = totalCalories else { return nil }
        return Double(totalCalories) / Double(targetCalories)
    }

    var proteinProgress: Double? {
        guard let totalProtein = totalProtein else { return nil }
        return Double(totalProtein) / Double(targetProtein)
    }

    var cardioProgress: Double? {
        guard let totalCardioCalories = totalCardioCalories else { return nil }
        return Double(totalCardioCalories) / Double(targetCardio)
    }
}
