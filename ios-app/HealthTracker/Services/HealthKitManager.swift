//
//  HealthKitManager.swift
//  HealthTracker
//
//  Manages all HealthKit data queries and permissions
//

import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitManager: ObservableObject {

    private let healthStore = HKHealthStore()

    // Published state
    @Published var isAuthorized = false
    @Published var authorizationError: Error?

    // MARK: - Health Data Types

    private let readTypes: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.bodyMass),
        HKQuantityType(.bodyFatPercentage),
        HKQuantityType(.leanBodyMass),
        HKObjectType.workoutType()
    ]

    // MARK: - Authorization

    /// Request HealthKit authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
        } catch {
            authorizationError = error
            isAuthorized = false
            throw error
        }
    }

    /// Check if we have authorization for all required types
    func checkAuthorization() -> Bool {
        for type in readTypes {
            let status = healthStore.authorizationStatus(for: type)
            if status != .sharingAuthorized {
                return false
            }
        }
        return true
    }

    // MARK: - Query Methods

    /// Fetch step count for a date range
    func fetchSteps(from startDate: Date, to endDate: Date) async throws -> Int {
        let type = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sum = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(sum))
            }

            healthStore.execute(query)
        }
    }

    /// Fetch total calories consumed for a date range
    func fetchCalories(from startDate: Date, to endDate: Date) async throws -> Int {
        let type = HKQuantityType(.dietaryEnergyConsumed)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sum = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: Int(sum))
            }

            healthStore.execute(query)
        }
    }

    /// Fetch total protein consumed for a date range
    func fetchProtein(from startDate: Date, to endDate: Date) async throws -> Int {
        let type = HKQuantityType(.dietaryProtein)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sum = result?.sumQuantity()?.doubleValue(for: .gram()) ?? 0
                continuation.resume(returning: Int(sum))
            }

            healthStore.execute(query)
        }
    }

    /// Fetch total cardio calories from workouts
    func fetchCardioCalories(from startDate: Date, to endDate: Date) async throws -> Int {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = samples as? [HKWorkout] ?? []
                let totalCalories = workouts.reduce(0.0) { sum, workout in
                    sum + (workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)
                }

                continuation.resume(returning: Int(totalCalories))
            }

            healthStore.execute(query)
        }
    }

    /// Fetch all weight readings for a date range
    func fetchWeightReadings(from startDate: Date, to endDate: Date) async throws -> [WeightReading] {
        let weightType = HKQuantityType(.bodyMass)
        let bodyFatType = HKQuantityType(.bodyFatPercentage)
        let muscleMassType = HKQuantityType(.leanBodyMass)

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        // Fetch weight samples
        let weightSamples = try await querySamples(type: weightType, predicate: predicate, sortDescriptor: sortDescriptor)

        // Fetch body composition samples
        let bodyFatSamples = try await querySamples(type: bodyFatType, predicate: predicate, sortDescriptor: sortDescriptor)
        let muscleMassSamples = try await querySamples(type: muscleMassType, predicate: predicate, sortDescriptor: sortDescriptor)

        // Create dictionary for quick lookup of body composition by date
        let bodyFatByDate = Dictionary(grouping: bodyFatSamples) { sample in
            Calendar.current.startOfDay(for: sample.startDate)
        }
        let muscleMassByDate = Dictionary(grouping: muscleMassSamples) { sample in
            Calendar.current.startOfDay(for: sample.startDate)
        }

        // Convert to WeightReading objects
        var readings: [WeightReading] = []

        for sample in weightSamples {
            let date = sample.startDate
            let dayStart = Calendar.current.startOfDay(for: date)

            let weight = sample.quantity.doubleValue(for: .pound())

            // Get body fat percentage for this day (if available)
            let bodyFat: Double?
            if let bodyFatSample = bodyFatByDate[dayStart]?.first {
                bodyFat = bodyFatSample.quantity.doubleValue(for: .percent()) * 100
            } else {
                bodyFat = nil
            }

            // Get muscle mass percentage for this day (if available)
            // Note: leanBodyMass is in kg, need to calculate percentage
            let muscleMass: Double?
            if let muscleMassSample = muscleMassByDate[dayStart]?.first {
                let leanMassKg = muscleMassSample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                let weightKg = weight * 0.453592 // Convert pounds to kg
                muscleMass = (leanMassKg / weightKg) * 100
            } else {
                muscleMass = nil
            }

            let reading = WeightReading(
                date: date,
                weight: weight,
                bodyFatPercentage: bodyFat,
                muscleMassPercentage: muscleMass,
                source: sample.sourceRevision.source.name
            )

            readings.append(reading)
        }

        return readings
    }

    /// Fetch daily metrics for a single day
    func fetchDailyMetrics(for date: Date) async throws -> DailyMetrics {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw HealthKitError.invalidDateRange
        }

        async let steps = fetchSteps(from: startOfDay, to: endOfDay)
        async let calories = fetchCalories(from: startOfDay, to: endOfDay)
        async let protein = fetchProtein(from: startOfDay, to: endOfDay)
        async let cardio = fetchCardioCalories(from: startOfDay, to: endOfDay)
        async let weights = fetchWeightReadings(from: startOfDay, to: endOfDay)

        let (s, c, p, cc, w) = try await (steps, calories, protein, cardio, weights)

        return DailyMetrics(
            date: startOfDay,
            steps: s,
            calories: c,
            protein: p,
            cardioCalories: cc,
            weight: w.first?.weight
        )
    }

    // MARK: - Private Helpers

    private func querySamples(
        type: HKQuantityType,
        predicate: NSPredicate,
        sortDescriptor: NSSortDescriptor
    ) async throws -> [HKQuantitySample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let quantitySamples = samples as? [HKQuantitySample] ?? []
                continuation.resume(returning: quantitySamples)
            }

            healthStore.execute(query)
        }
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case invalidDateRange
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .invalidDateRange:
            return "Invalid date range provided"
        case .unauthorized:
            return "HealthKit access not authorized"
        }
    }
}
