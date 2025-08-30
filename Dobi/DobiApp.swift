//
//  DobiApp.swift
//  Dobi
//
//  Created by Kevin Wijaya on 8/30/25.
//

import SwiftUI
import SwiftData

@main
struct DobiApp: App {
    @StateObject private var themeManager = ThemeManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Book.self,
            Chapter.self,
            ReadingProgress.self,
            Bookmark.self,
            Highlight.self,
            Note.self,
            UserPreferences.self
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
            ThemedContentView()
                .environmentObject(themeManager)
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ThemedContentView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ContentView()
            .environment(\.theme, themeManager.currentTheme)
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .background(themeManager.currentTheme.background)
    }
}
