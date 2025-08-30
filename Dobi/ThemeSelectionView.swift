//
//  ThemeSelectionView.swift
//  Dobi
//
//  Created by Kevin Wijaya on 8/30/25.
//

import SwiftUI

struct ThemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingCustomThemeBuilder = false
    @State private var selectedThemeForDeletion: CustomTheme?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationView {
            List {
                Section("Built-in Themes") {
                    ForEach(themeManager.allThemes.filter { !$0.isCustom }, id: \.id) { theme in
                        ThemeRowView(theme: theme, isSelected: themeManager.currentTheme.id == theme.id) {
                            themeManager.selectTheme(theme)
                        }
                    }
                }

                Section("Custom Themes") {
                    ForEach(themeManager.customThemes, id: \.id) { theme in
                        ThemeRowView(
                            theme: theme,
                            isSelected: themeManager.currentTheme.id == theme.id,
                            showDelete: true
                        ) {
                            themeManager.selectTheme(theme)
                        } onDelete: {
                            selectedThemeForDeletion = theme
                            showingDeleteConfirmation = true
                        }
                    }

                    Button {
                        showingCustomThemeBuilder = true
                    } label: {
                        Label("Create Custom Theme", systemImage: "plus")
                    }
                }

                Section("Schedule Settings") {
                    ThemeScheduleView()
                }
            }
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCustomThemeBuilder) {
                CustomThemeBuilderView()
            }
            .alert("Delete Theme", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let theme = selectedThemeForDeletion {
                        themeManager.deleteCustomTheme(theme)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this custom theme? This action cannot be undone.")
            }
        }
    }
}

struct ThemeRowView: View {
    let theme: any Theme
    let isSelected: Bool
    let showDelete: Bool
    let onSelect: () -> Void
    let onDelete: (() -> Void)?

    init(
        theme: any Theme,
        isSelected: Bool,
        showDelete: Bool = false,
        onSelect: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.theme = theme
        self.isSelected = isSelected
        self.showDelete = showDelete
        self.onSelect = onSelect
        self.onDelete = onDelete
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(theme.name)
                        .font(.headline)
                        .foregroundColor(theme.text)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(theme.accent)
                    }
                }

                ThemePreview(theme: theme)
                    .frame(height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack {
                    Text("Sample text preview")
                        .font(.caption)
                        .foregroundColor(theme.text)

                    Spacer()

                    ContrastBadge(theme: theme)
                }
            }

            if showDelete {
                Button {
                    onDelete?()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(12)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

struct ThemePreview: View {
    let theme: any Theme

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(theme.background)
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(theme.text)
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(theme.accent)
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(theme.secondary)
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(theme.surface)
                .frame(maxWidth: .infinity)
        }
    }
}

struct ContrastBadge: View {
    let theme: any Theme

    var body: some View {
        let meetsAAA = theme.meetsWCAGAAA
        let meetsAA = theme.meetsWCAGAA

        HStack(spacing: 4) {
            if meetsAAA {
                Text("AAA")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else if meetsAA {
                Text("AA")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Text("FAIL")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}

struct ThemeScheduleView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Schedule", selection: Binding(
                get: { themeManager.scheduleSettings.schedule },
                set: { newValue in
                    var settings = themeManager.scheduleSettings
                    settings.schedule = newValue
                    themeManager.updateScheduleSettings(settings)
                }
            )) {
                ForEach(ThemeSchedule.allCases, id: \.self) { schedule in
                    Text(schedule.displayName).tag(schedule)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            if themeManager.scheduleSettings.schedule == .scheduled {
                VStack(spacing: 8) {
                    HStack {
                        Text("Light Theme")
                        Spacer()
                        DatePicker("", selection: Binding(
                            get: { themeManager.scheduleSettings.lightThemeStartTime },
                            set: { newTime in
                                var settings = themeManager.scheduleSettings
                                settings.lightThemeStartTime = newTime
                                themeManager.updateScheduleSettings(settings)
                            }
                        ), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    }

                    HStack {
                        Text("Dark Theme")
                        Spacer()
                        DatePicker("", selection: Binding(
                            get: { themeManager.scheduleSettings.darkThemeStartTime },
                            set: { newTime in
                                var settings = themeManager.scheduleSettings
                                settings.darkThemeStartTime = newTime
                                themeManager.updateScheduleSettings(settings)
                            }
                        ), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    }
                }
            }

            if themeManager.scheduleSettings.schedule == .ambient {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ambient Light Threshold")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Dark")
                            .font(.caption)

                        Slider(value: Binding(
                            get: { themeManager.scheduleSettings.ambientLightThreshold },
                            set: { newValue in
                                var settings = themeManager.scheduleSettings
                                settings.ambientLightThreshold = newValue
                                themeManager.updateScheduleSettings(settings)
                            }
                        ), in: 0...1)

                        Text("Light")
                            .font(.caption)
                    }

                    Text("Note: Ambient light detection requires camera permissions.")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

#Preview {
    let themeManager = ThemeManager.preview()
    return ThemeSelectionView()
        .environmentObject(themeManager)
        .environment(\.theme, themeManager.currentTheme)
}
