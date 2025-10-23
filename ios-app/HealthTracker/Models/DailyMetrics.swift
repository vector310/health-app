//
//  DailyMetrics.swift
//  HealthTracker
//
//  Model for daily aggregated health metrics
//

import Foundation

struct DailyMetrics: Codable, Identifiable {
    let id: UUID
    let date: Date
    let steps: Int
    let calories: Int
    let protein: Int
    let cardioCalories: Int
    let weight: Double?
    let sevenDayAverageWeight: Double?

    init(
        id: UUID = UUID(),
        date: Date,
        steps: Int = 0,
        calories: Int = 0,
        protein: Int = 0,
        cardioCalories: Int = 0,
        weight: Double? = nil,
        sevenDayAverageWeight: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.steps = steps
        self.calories = calories
        self.protein = protein
        self.cardioCalories = cardioCalories
        self.weight = weight
        self.sevenDayAverageWeight = sevenDayAverageWeight
    }
}
