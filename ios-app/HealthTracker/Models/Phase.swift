//
//  Phase.swift
//  HealthTracker
//
//  Training phase enumeration
//

import Foundation

enum Phase: String, Codable, CaseIterable {
    case cut = "cut"
    case maintenance = "maintenance"
    case bulk = "bulk"

    var displayName: String {
        switch self {
        case .cut:
            return "Cut"
        case .maintenance:
            return "Maintenance"
        case .bulk:
            return "Bulk"
        }
    }

    var color: String {
        switch self {
        case .cut:
            return "red"
        case .maintenance:
            return "yellow"
        case .bulk:
            return "green"
        }
    }
}
