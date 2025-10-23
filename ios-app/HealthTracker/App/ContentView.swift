//
//  ContentView.swift
//  HealthTracker
//
//  Root navigation with tab bar
//

import SwiftUI

struct ContentView: View {

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)

            // History Tab
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(1)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthKitManager())
        .environmentObject(APIService())
        .environmentObject(CacheManager())
}
