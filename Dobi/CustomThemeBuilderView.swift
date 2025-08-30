//
//  CustomThemeBuilderView.swift
//  Dobi
//
//  Created by Kevin Wijaya on 8/30/25.
//

import SwiftUI

struct CustomThemeBuilderView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var themeName = ""
    @State private var backgroundColor = Color.white
    @State private var textColor = Color.black
    @State private var accentColor = Color.blue
    @State private var secondaryColor = Color.gray
    @State private var surfaceColor = Color(white: 0.95)

    @State private var showingColorPicker: ColorType?
    @State private var showingImportAlert = false
    @State private var importErrorMessage = ""

    enum ColorType: String, CaseIterable, Identifiable {
        case background = "Background"
        case text = "Text"
        case accent = "Accent"
        case secondary = "Secondary"
        case surface = "Surface"

        var id: String { self.rawValue }
    }

    private var previewTheme: CustomTheme {
        CustomTheme(
            name: themeName.isEmpty ? "Preview" : themeName,
            background: backgroundColor,
            text: textColor,
            accent: accentColor,
            secondary: secondaryColor,
            surface: surfaceColor
        )
    }

    private var contrastRatio: Double {
        previewTheme.contrastRatio(background: backgroundColor, text: textColor)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    themeNameSection
                    colorPickerSection
                    previewSection
                    contrastSection
                    importExportSection
                }
                .padding()
            }
            .navigationTitle("Create Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTheme()
                    }
                    .disabled(themeName.isEmpty)
                }
            }
            .sheet(item: $showingColorPicker) { colorType in
                ColorPickerSheet(
                    colorType: colorType,
                    selectedColor: binding(for: colorType),
                    onDismiss: { showingColorPicker = nil }
                )
            }
            .alert("Import Error", isPresented: $showingImportAlert) {
                Button("OK") { }
            } message: {
                Text(importErrorMessage)
            }
        }
    }

    private var themeNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Theme Name")
                .font(.headline)

            TextField("Enter theme name", text: $themeName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }

    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Colors")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(ColorType.allCases, id: \.self) { colorType in
                    ColorPickerButton(
                        title: colorType.rawValue,
                        color: binding(for: colorType).wrappedValue
                    ) {
                        showingColorPicker = colorType
                    }
                }
            }
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)

            VStack(spacing: 16) {
                ThemePreview(theme: previewTheme)
                    .frame(height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Sample Book Title")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(previewTheme.text)

                    Text("by Author Name")
                        .font(.subheadline)
                        .foregroundColor(previewTheme.secondary)

                    Text("This is how your text will appear when reading. The quick brown fox jumps over the lazy dog.")
                        .font(.body)
                        .foregroundColor(previewTheme.text)
                        .lineLimit(3)
                }
                .padding()
                .background(previewTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .background(previewTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(4)
        }
    }

    private var contrastSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accessibility")
                .font(.headline)

            VStack(spacing: 8) {
                HStack {
                    Text("Contrast Ratio")
                    Spacer()
                    Text(String(format: "%.1f:1", contrastRatio))
                        .fontWeight(.medium)
                }

                HStack {
                    Text("WCAG Compliance")
                    Spacer()

                    if previewTheme.meetsWCAGAAA {
                        Text("AAA")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else if previewTheme.meetsWCAGAA {
                        Text("AA")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Text("FAIL")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                if !previewTheme.meetsWCAGAA {
                    Text(
                        "Consider adjusting colors to meet WCAG AA standards (4.5:1 contrast ratio) for better accessibility."
                    )
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var importExportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import/Export")
                .font(.headline)

            HStack(spacing: 16) {
                Button("Import Theme") {
                    // TODO: Implement file picker for theme import
                    importErrorMessage = "Theme import feature coming soon!"
                    showingImportAlert = true
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Export Current") {
                    // TODO: Implement theme export
                }
                .buttonStyle(.bordered)
                .disabled(themeName.isEmpty)
            }
        }
    }

    private func binding(for colorType: ColorType) -> Binding<Color> {
        switch colorType {
        case .background:
            return $backgroundColor
        case .text:
            return $textColor
        case .accent:
            return $accentColor
        case .secondary:
            return $secondaryColor
        case .surface:
            return $surfaceColor
        }
    }

    private func saveTheme() {
        let theme = themeManager.createCustomTheme(
            name: themeName,
            background: backgroundColor,
            text: textColor,
            accent: accentColor,
            secondary: secondaryColor,
            surface: surfaceColor
        )

        themeManager.selectTheme(theme)
        dismiss()
    }
}

struct ColorPickerButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                    )

                Text(title)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ColorPickerSheet: View {
    let colorType: CustomThemeBuilderView.ColorType
    @Binding var selectedColor: Color
    let onDismiss: () -> Void

    @State private var hue: Double = 0
    @State private var saturation: Double = 1
    @State private var brightness: Double = 1
    @State private var alpha: Double = 1

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Choose \(colorType.rawValue) Color")
                    .font(.title2)
                    .fontWeight(.medium)

                ColorPicker("Color", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(1.5)

                VStack(spacing: 16) {
                    ColorSlider(label: "Hue", value: $hue, range: 0...1, color: .red)
                    ColorSlider(label: "Saturation", value: $saturation, range: 0...1, color: .blue)
                    ColorSlider(label: "Brightness", value: $brightness, range: 0...1, color: .yellow)
                }

                Rectangle()
                    .fill(selectedColor)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
        .onAppear {
            updateSlidersFromColor()
        }
        .onChange(of: hue) { updateColorFromSliders() }
        .onChange(of: saturation) { updateColorFromSliders() }
        .onChange(of: brightness) { updateColorFromSliders() }
    }

    private func updateSlidersFromColor() {
        let uiColor = UIColor(selectedColor)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        self.hue = Double(hue)
        self.saturation = Double(saturation)
        self.brightness = Double(brightness)
        self.alpha = Double(alpha)
    }

    private func updateColorFromSliders() {
        selectedColor = Color(hue: hue, saturation: saturation, brightness: brightness, opacity: alpha)
    }
}

struct ColorSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Slider(value: $value, in: range) {
                Text(label)
            }
            .accentColor(color)
        }
    }
}

#Preview {
    let themeManager = ThemeManager.preview()
    return CustomThemeBuilderView()
        .environmentObject(themeManager)
        .environment(\.theme, themeManager.currentTheme)
}
