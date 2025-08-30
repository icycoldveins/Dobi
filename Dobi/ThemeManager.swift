//
//  ThemeManager.swift
//  Dobi
//
//  Created by Kevin Wijaya on 8/30/25.
//

import SwiftUI
import Foundation
import Combine

@MainActor
class ThemeManager: ObservableObject {
    @Published var currentTheme: any Theme = LightTheme()
    @Published var scheduleSettings = ThemeScheduleSettings()
    @Published var customThemes: [CustomTheme] = []
    @Published var isSystemDarkMode: Bool = false

    private let builtInThemes: [any Theme] = [
        LightTheme(),
        DarkTheme(),
        SepiaTheme()
    ]

    private var systemThemeObserver: AnyCancellable?
    private var scheduleTimer: Timer?

    init() {
        loadThemeSettings()
        setupSystemThemeObserver()
        setupScheduleTimer()
        updateCurrentTheme()
    }

    deinit {
        systemThemeObserver?.cancel()
        scheduleTimer?.invalidate()
    }

    var allThemes: [any Theme] {
        return builtInThemes + customThemes
    }

    func selectTheme(_ theme: any Theme) {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentTheme = theme
        }
        saveThemeSettings()
    }

    func selectThemeById(_ id: String) {
        if let theme = allThemes.first(where: { $0.id == id }) {
            selectTheme(theme)
        }
    }

    func createCustomTheme(
        name: String,
        background: Color,
        text: Color,
        accent: Color,
        secondary: Color,
        surface: Color,
        colorScheme: ColorScheme = .light
    ) -> CustomTheme {
        let theme = CustomTheme(
            name: name,
            background: background,
            text: text,
            accent: accent,
            secondary: secondary,
            surface: surface,
            colorScheme: colorScheme
        )

        customThemes.append(theme)
        saveThemeSettings()

        return theme
    }

    func updateCustomTheme(_ theme: CustomTheme) {
        if let index = customThemes.firstIndex(where: { $0.id == theme.id }) {
            customThemes[index] = theme

            if currentTheme.id == theme.id {
                currentTheme = theme
            }

            saveThemeSettings()
        }
    }

    func deleteCustomTheme(_ theme: CustomTheme) {
        customThemes.removeAll { $0.id == theme.id }

        if currentTheme.id == theme.id {
            currentTheme = LightTheme()
        }

        saveThemeSettings()
    }

    func updateScheduleSettings(_ settings: ThemeScheduleSettings) {
        scheduleSettings = settings
        saveThemeSettings()
        setupScheduleTimer()
        updateCurrentTheme()
    }

    private func setupSystemThemeObserver() {
        systemThemeObserver = NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateSystemThemeState()
                }
            }

        updateSystemThemeState()
    }

    private func updateSystemThemeState() {
        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        if isSystemDarkMode != isDark {
            isSystemDarkMode = isDark
            if scheduleSettings.schedule == .system {
                updateCurrentTheme()
            }
        }
    }

    private func setupScheduleTimer() {
        scheduleTimer?.invalidate()

        guard scheduleSettings.schedule == .scheduled else { return }

        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCurrentTheme()
            }
        }
    }

    private func updateCurrentTheme() {
        let newTheme: any Theme

        switch scheduleSettings.schedule {
        case .manual:
            return

        case .system:
            newTheme = isSystemDarkMode ? DarkTheme() : LightTheme()

        case .scheduled:
            newTheme = shouldUseDarkThemeForSchedule() ? DarkTheme() : LightTheme()

        case .ambient:
            newTheme = shouldUseDarkThemeForAmbientLight() ? DarkTheme() : LightTheme()
        }

        if currentTheme.id != newTheme.id {
            selectTheme(newTheme)
        }
    }

    private func shouldUseDarkThemeForSchedule() -> Bool {
        let calendar = Calendar.current
        let now = Date()

        let lightStart = scheduleSettings.lightThemeStartTime
        let darkStart = scheduleSettings.darkThemeStartTime

        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let lightTime = calendar.dateComponents([.hour, .minute], from: lightStart)
        let darkTime = calendar.dateComponents([.hour, .minute], from: darkStart)

        let currentMinutes = (currentTime.hour ?? 0) * 60 + (currentTime.minute ?? 0)
        let lightMinutes = (lightTime.hour ?? 0) * 60 + (lightTime.minute ?? 0)
        let darkMinutes = (darkTime.hour ?? 0) * 60 + (darkTime.minute ?? 0)

        if lightMinutes < darkMinutes {
            return currentMinutes >= darkMinutes || currentMinutes < lightMinutes
        } else {
            return currentMinutes >= darkMinutes && currentMinutes < lightMinutes
        }
    }

    private func shouldUseDarkThemeForAmbientLight() -> Bool {
        return false
    }

    private func loadThemeSettings() {
        if let data = UserDefaults.standard.data(forKey: "ThemeSettings"),
           let settings = try? JSONDecoder().decode(ThemeSettings.self, from: data) {

            scheduleSettings = settings.scheduleSettings
            customThemes = settings.customThemes

            if let themeId = settings.currentThemeId,
               let theme = allThemes.first(where: { $0.id == themeId }) {
                currentTheme = theme
            }
        }
    }

    private func saveThemeSettings() {
        let settings = ThemeSettings(
            currentThemeId: currentTheme.id,
            scheduleSettings: scheduleSettings,
            customThemes: customThemes
        )

        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "ThemeSettings")
        }
    }

    func exportTheme(_ theme: CustomTheme) -> Data? {
        return try? JSONEncoder().encode(theme)
    }

    func importTheme(from data: Data) -> Bool {
        guard let theme = try? JSONDecoder().decode(CustomTheme.self, from: data) else {
            return false
        }

        let newTheme = CustomTheme(
            name: theme.name,
            background: theme.background,
            text: theme.text,
            accent: theme.accent,
            secondary: theme.secondary,
            surface: theme.surface,
            colorScheme: theme.colorScheme
        )

        customThemes.append(newTheme)
        saveThemeSettings()

        return true
    }
}

private struct ThemeSettings: Codable {
    let currentThemeId: String?
    let scheduleSettings: ThemeScheduleSettings
    let customThemes: [CustomTheme]
}

extension ThemeManager {
    static let shared = ThemeManager()

    static func preview() -> ThemeManager {
        let manager = ThemeManager()
        return manager
    }
}

struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: any Theme = LightTheme()
}

extension EnvironmentValues {
    var theme: any Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

extension View {
    func themed() -> some View {
        ThemedWrapper(content: self)
    }
}

private struct ThemedWrapper<Content: View>: View {
    let content: Content
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        content
            .environmentObject(themeManager)
            .environment(\.theme, themeManager.currentTheme)
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .background(themeManager.currentTheme.background)
    }
}
