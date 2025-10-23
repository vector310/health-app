//
//  DateHelpers.swift
//  HealthTracker
//
//  Utilities for working with week boundaries and date ranges
//

import Foundation

struct DateHelpers {

    /// Get the start of the week (Sunday at 00:00:00) for a given date
    static func weekStart(for date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 1 // Sunday
        return calendar.date(from: components) ?? date
    }

    /// Get the end of the week (Saturday at 23:59:59) for a given date
    static func weekEnd(for date: Date) -> Date {
        let start = weekStart(for: date)
        var components = DateComponents()
        components.day = 6
        components.hour = 23
        components.minute = 59
        components.second = 59
        return Calendar.current.date(byAdding: components, to: start) ?? date
    }

    /// Get the current week's boundaries
    static func currentWeekBoundaries() -> (start: Date, end: Date) {
        let now = Date()
        return (weekStart(for: now), weekEnd(for: now))
    }

    /// Check if a date is in the current week
    static func isCurrentWeek(_ date: Date) -> Bool {
        let boundaries = currentWeekBoundaries()
        return date >= boundaries.start && date <= boundaries.end
    }

    /// Get week boundaries for N weeks ago
    static func weekBoundaries(weeksAgo: Int) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        guard let targetDate = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date()) else {
            return currentWeekBoundaries()
        }
        return (weekStart(for: targetDate), weekEnd(for: targetDate))
    }

    /// Get an array of week boundaries for the last N weeks
    static func lastNWeeks(count: Int) -> [(start: Date, end: Date)] {
        var weeks: [(start: Date, end: Date)] = []
        for i in 0..<count {
            weeks.append(weekBoundaries(weeksAgo: i))
        }
        return weeks
    }

    /// Format date range as "Oct 13 - Oct 19"
    static func formatWeekRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    /// Check if today is Sunday before 10am (check-in time)
    static func isCheckInTime() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.weekday, .hour], from: now)
        return components.weekday == 1 && (components.hour ?? 0) < 10
    }
}
