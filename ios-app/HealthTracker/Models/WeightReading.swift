//
//  WeightReading.swift
//  HealthTracker
//
//  Model for individual weight/body composition readings
//

import Foundation

struct WeightReading: Codable, Identifiable {
    let id: UUID
    let date: Date
    let weight: Double // in pounds
    let bodyFatPercentage: Double?
    let muscleMassPercentage: Double?
    let source: String

    init(
        id: UUID = UUID(),
        date: Date,
        weight: Double,
        bodyFatPercentage: Double? = nil,
        muscleMassPercentage: Double? = nil,
        source: String = "Apple Health"
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.bodyFatPercentage = bodyFatPercentage
        self.muscleMassPercentage = muscleMassPercentage
        self.source = source
    }
}

// MARK: - Comparable

extension WeightReading: Comparable {
    static func < (lhs: WeightReading, rhs: WeightReading) -> Bool {
        lhs.date < rhs.date
    }
}
