//
//  ReaderView.swift
//  Dobi
//
//  Created by Kevin Wijaya on 8/30/25.
//

import SwiftUI
import SwiftData

struct ReaderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme

    let book: Book
    @State private var currentChapterIndex: Int = 0
    @State private var isToolbarVisible: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showingThemeSelection = false

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if !book.chapters.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Chapter Title
                            Text(book.chapters[currentChapterIndex].title)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.text)
                                .padding(.horizontal)
                                .padding(.top)

                            // Chapter Content (simplified HTML rendering for now)
                            Text(stripHTML(book.chapters[currentChapterIndex].htmlContent))
                                .font(.body)
                                .foregroundColor(theme.text)
                                .lineSpacing(4)
                                .padding(.horizontal)

                            Spacer(minLength: 100)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isToolbarVisible.toggle()
                        }
                    }
                } else {
                    // No chapters available
                    VStack {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(theme.secondary)

                        Text("No chapters available")
                            .font(.headline)
                            .foregroundColor(theme.secondary)
                            .padding(.top)

                        Text("This book appears to be empty or hasn't been processed yet.")
                            .font(.caption)
                            .foregroundColor(theme.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }

            // Reading Toolbar (overlay)
            VStack {
                Spacer()

                if isToolbarVisible {
                    VStack(spacing: 12) {
                        // Theme and Settings Row
                        HStack {
                            Button {
                                showingThemeSelection = true
                            } label: {
                                Image(systemName: "paintbrush")
                                    .font(.title2)
                                    .foregroundColor(theme.accent)
                            }

                            Spacer()

                            Button {
                                // TODO: Add brightness control
                            } label: {
                                Image(systemName: "sun.max")
                                    .font(.title2)
                                    .foregroundColor(theme.accent)
                            }

                            Button {
                                // TODO: Add font settings
                            } label: {
                                Image(systemName: "textformat.size")
                                    .font(.title2)
                                    .foregroundColor(theme.accent)
                            }
                        }

                        Divider()
                            .background(theme.secondary)

                        // Navigation Row
                        HStack {
                            // Previous Chapter
                            Button {
                                previousChapter()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(theme.accent)
                            }
                            .disabled(currentChapterIndex == 0)

                            Spacer()

                            // Chapter Info
                            VStack {
                                Text("Chapter \(currentChapterIndex + 1) of \(book.chapters.count)")
                                    .font(.caption)
                                    .foregroundColor(theme.secondary)

                                ProgressView(value: Double(currentChapterIndex + 1), total: Double(book.chapters.count))
                                    .progressViewStyle(LinearProgressViewStyle(tint: theme.accent))
                                    .frame(width: 100)
                            }

                            Spacer()

                            // Next Chapter
                            Button {
                                nextChapter()
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundColor(theme.accent)
                            }
                            .disabled(currentChapterIndex >= book.chapters.count - 1)
                        }
                    }
                    .padding()
                    .background(theme.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .padding()
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(theme.accent)
            }
        }
        .sheet(isPresented: $showingThemeSelection) {
            ThemeSelectionView()
        }
        .onAppear {
            updateLastOpened()
            loadReadingProgress()
        }
        .onDisappear {
            saveReadingProgress()
        }
    }

    // MARK: - Helper Functions

    private func stripHTML(_ html: String) -> String {
        // Simple HTML tag removal for now
        // In a full implementation, you'd want proper HTML parsing
        return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }

    private func previousChapter() {
        guard currentChapterIndex > 0 else { return }
        withAnimation {
            currentChapterIndex -= 1
        }
        saveReadingProgress()
    }

    private func nextChapter() {
        guard currentChapterIndex < book.chapters.count - 1 else { return }
        withAnimation {
            currentChapterIndex += 1
        }
        saveReadingProgress()
    }

    private func updateLastOpened() {
        book.lastOpened = Date()
        try? modelContext.save()
    }

    private func loadReadingProgress() {
        if let progress = book.readingProgress {
            // Find the chapter index by ID
            if let chapterIndex = book.chapters.firstIndex(where: { $0.id == progress.currentChapter }) {
                currentChapterIndex = chapterIndex
            }
        }
    }

    private func saveReadingProgress() {
        if book.readingProgress == nil {
            book.readingProgress = ReadingProgress()
        }

        if let progress = book.readingProgress, currentChapterIndex < book.chapters.count {
            progress.currentChapter = book.chapters[currentChapterIndex].id
            progress.currentPosition = 0.0 // TODO: Calculate actual scroll position
            progress.lastRead = Date()
        }

        try? modelContext.save()
    }
}

#Preview {
    let themeManager = ThemeManager.preview()
    return NavigationView {
        ReaderView(book: Book(title: "Sample Book", author: "Sample Author", filePath: URL(fileURLWithPath: "/sample")))
    }
    .modelContainer(for: Book.self, inMemory: true)
    .environmentObject(themeManager)
    .environment(\.theme, themeManager.currentTheme)
}
