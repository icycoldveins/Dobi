//
//  Theme.swift
//  Dobi
//
//  Created by Kevin Wijaya on 8/30/25.
//

import SwiftUI
import Foundation

protocol Theme {
    var id: String { get }
    var name: String { get }
    var background: Color { get }
    var text: Color { get }
    var accent: Color { get }
    var secondary: Color { get }
    var surface: Color { get }
    var isCustom: Bool { get }
    var colorScheme: ColorScheme { get }
}

struct LightTheme: Theme {
    let id = "light"
    let name = "Light"
    let background = Color.white
    let text = Color.black
    let accent = Color.blue
    let secondary = Color.gray
    let surface = Color(red: 0.95, green: 0.95, blue: 0.97)
    let isCustom = false
    let colorScheme = ColorScheme.light
}

struct DarkTheme: Theme {
    let id = "dark"
    let name = "Dark"
    let background = Color(red: 0.1, green: 0.1, blue: 0.1)
    let text = Color.white
    let accent = Color(red: 0.3, green: 0.7, blue: 1.0)
    let secondary = Color(red: 0.7, green: 0.7, blue: 0.7)
    let surface = Color(red: 0.15, green: 0.15, blue: 0.15)
    let isCustom = false
    let colorScheme = ColorScheme.dark
}

struct SepiaTheme: Theme {
    let id = "sepia"
    let name = "Sepia"
    let background = Color(red: 0.98, green: 0.94, blue: 0.87)
    let text = Color(red: 0.20, green: 0.15, blue: 0.10)
    let accent = Color(red: 0.65, green: 0.45, blue: 0.25)
    let secondary = Color(red: 0.40, green: 0.30, blue: 0.20)
    let surface = Color(red: 0.95, green: 0.91, blue: 0.84)
    let isCustom = false
    let colorScheme = ColorScheme.light
}

struct CustomTheme: Theme {
    let id: String
    let name: String
    let background: Color
    let text: Color
    let accent: Color
    let secondary: Color
    let surface: Color
    let isCustom = true
    let colorScheme: ColorScheme

    init(
        id: String = UUID().uuidString,
        name: String,
        background: Color,
        text: Color,
        accent: Color,
        secondary: Color,
        surface: Color,
        colorScheme: ColorScheme = .light
    ) {
        self.id = id
        self.name = name
        self.background = background
        self.text = text
        self.accent = accent
        self.secondary = secondary
        self.surface = surface
        self.colorScheme = colorScheme
    }
}

extension CustomTheme: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, background, text, accent, secondary, surface, colorScheme
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        background = Color(try container.decode(ColorComponents.self, forKey: .background))
        text = Color(try container.decode(ColorComponents.self, forKey: .text))
        accent = Color(try container.decode(ColorComponents.self, forKey: .accent))
        secondary = Color(try container.decode(ColorComponents.self, forKey: .secondary))
        surface = Color(try container.decode(ColorComponents.self, forKey: .surface))

        if let colorSchemeRawValue = try container.decodeIfPresent(String.self, forKey: .colorScheme) {
            colorScheme = colorSchemeRawValue == "dark" ? .dark : .light
        } else {
            colorScheme = .light
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(ColorComponents(background), forKey: .background)
        try container.encode(ColorComponents(text), forKey: .text)
        try container.encode(ColorComponents(accent), forKey: .accent)
        try container.encode(ColorComponents(secondary), forKey: .secondary)
        try container.encode(ColorComponents(surface), forKey: .surface)
        try container.encode(colorScheme == .dark ? "dark" : "light", forKey: .colorScheme)
    }
}

struct ColorComponents: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init(_ color: Color) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.alpha = Double(alpha)
    }
}

extension Color {
    init(_ components: ColorComponents) {
        self.init(
            red: components.red,
            green: components.green,
            blue: components.blue,
            opacity: components.alpha
        )
    }
}

enum ThemeSchedule: String, CaseIterable {
    case manual
    case system
    case scheduled
    case ambient

    var displayName: String {
        switch self {
        case .manual:
            return "Manual"
        case .system:
            return "Follow System"
        case .scheduled:
            return "Scheduled"
        case .ambient:
            return "Ambient Light"
        }
    }
}

struct ThemeScheduleSettings: Codable {
    var schedule: ThemeSchedule
    var lightThemeStartTime: Date
    var darkThemeStartTime: Date
    var ambientLightThreshold: Double

    init() {
        self.schedule = .system

        let calendar = Calendar.current
        let now = Date()

        self.lightThemeStartTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now
        self.darkThemeStartTime = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: now) ?? now
        self.ambientLightThreshold = 0.5
    }
}

extension ThemeSchedule: Codable {}

extension Theme {
    func contrastRatio(background: Color, text: Color) -> Double {
        let bgLuminance = relativeLuminance(background)
        let textLuminance = relativeLuminance(text)

        let lighter = max(bgLuminance, textLuminance)
        let darker = min(bgLuminance, textLuminance)

        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(_ color: Color) -> Double {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let redComponent = linearizeColorComponent(Double(red))
        let greenComponent = linearizeColorComponent(Double(green))
        let blueComponent = linearizeColorComponent(Double(blue))

        return 0.2126 * redComponent + 0.7152 * greenComponent + 0.0722 * blueComponent
    }

    private func linearizeColorComponent(_ component: Double) -> Double {
        if component <= 0.03928 {
            return component / 12.92
        } else {
            return pow((component + 0.055) / 1.055, 2.4)
        }
    }

    var meetsWCAGAA: Bool {
        contrastRatio(background: background, text: text) >= 4.5
    }

    var meetsWCAGAAA: Bool {
        contrastRatio(background: background, text: text) >= 7.0
    }
}
