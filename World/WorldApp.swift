//
//  WorldApp.swift
//  World
//
//  Created by Skyler on 2/28/26.
//

import SwiftUI
import SwiftData

@main
struct WorldApp: App {
    init() {
        NavigationBarStyle.apply()
        NotificationManager.requestPermissionAndScheduleDaily(hour: 7, minute: 0)
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
