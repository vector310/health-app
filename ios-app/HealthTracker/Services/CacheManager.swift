//
//  CacheManager.swift
//  HealthTracker
//
//  Local caching for offline access
//

import Foundation
import Combine

@MainActor
class CacheManager: ObservableObject {

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // Cache keys
    private enum CacheKey: String, CaseIterable {
        case currentWeek = "cache.currentWeek"
        case recentWeeks = "cache.recentWeeks"
        case weightReadings = "cache.weightReadings"
        case userProfile = "cache.userProfile"
    }

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Current Week

    func cacheCurrentWeek(_ week: WeekRecord) {
        if let data = try? encoder.encode(week) {
            defaults.set(data, forKey: CacheKey.currentWeek.rawValue)
        }
    }

    func getCachedCurrentWeek() -> WeekRecord? {
        guard let data = defaults.data(forKey: CacheKey.currentWeek.rawValue) else {
            return nil
        }
        return try? decoder.decode(WeekRecord.self, from: data)
    }

    // MARK: - Recent Weeks

    func cacheRecentWeeks(_ weeks: [WeekRecord]) {
        if let data = try? encoder.encode(weeks) {
            defaults.set(data, forKey: CacheKey.recentWeeks.rawValue)
        }
    }

    func getCachedRecentWeeks() -> [WeekRecord]? {
        guard let data = defaults.data(forKey: CacheKey.recentWeeks.rawValue) else {
            return nil
        }
        return try? decoder.decode([WeekRecord].self, from: data)
    }

    // MARK: - Weight Readings

    func cacheWeightReadings(_ readings: [WeightReading]) {
        if let data = try? encoder.encode(readings) {
            defaults.set(data, forKey: CacheKey.weightReadings.rawValue)
        }
    }

    func getCachedWeightReadings() -> [WeightReading]? {
        guard let data = defaults.data(forKey: CacheKey.weightReadings.rawValue) else {
            return nil
        }
        return try? decoder.decode([WeightReading].self, from: data)
    }

    // MARK: - User Profile

    func cacheUserProfile(_ profile: CalorieBalanceCalculator.UserProfile) {
        if let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: CacheKey.userProfile.rawValue)
        }
    }

    func getCachedUserProfile() -> CalorieBalanceCalculator.UserProfile? {
        guard let data = defaults.data(forKey: CacheKey.userProfile.rawValue) else {
            return nil
        }
        return try? decoder.decode(CalorieBalanceCalculator.UserProfile.self, from: data)
    }

    // MARK: - Clear Cache

    func clearAll() {
        CacheKey.allCases.forEach { key in
            defaults.removeObject(forKey: key.rawValue)
        }
    }

    func clearWeeks() {
        defaults.removeObject(forKey: CacheKey.currentWeek.rawValue)
        defaults.removeObject(forKey: CacheKey.recentWeeks.rawValue)
    }
}
