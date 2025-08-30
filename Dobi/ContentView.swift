//
//  ContentView.swift
//  Dobi
//
//  Created by Kevin Wijaya on 8/30/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme
    @State private var showingThemeSelection = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(books) { book in
                    NavigationLink {
                        ReaderView(book: book)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(book.title)
                                .font(.headline)
                                .foregroundColor(theme.text)
                            Text("by \(book.author)")
                                .font(.caption)
                                .foregroundColor(theme.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(theme.surface)
                }
                .onDelete(perform: deleteBooks)
            }
            .background(theme.background)
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Themes") {
                        showingThemeSelection = true
                    }
                    .foregroundColor(theme.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .foregroundColor(theme.accent)
                }
                ToolbarItem {
                    Button(action: addSampleBook) {
                        Label("Add Book", systemImage: "plus")
                    }
                    .foregroundColor(theme.accent)
                }
            }
            .navigationTitle("Library")
        } detail: {
            Text("Select a book")
                .foregroundColor(theme.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.background)
        }
        .background(theme.background)
        .accentColor(theme.accent)
        .sheet(isPresented: $showingThemeSelection) {
            ThemeSelectionView()
        }
        .onAppear {
            if books.isEmpty {
                addSampleBook()
            }
        }
    }

    private func addSampleBook() {
        withAnimation {
            let sampleBook = Book(
                title: "The Adventures of Alice",
                author: "Lewis Carroll",
                filePath: URL(fileURLWithPath: "/sample/path")
            )

            // Add sample chapters
            let chapter1 = Chapter(
                id: "ch1",
                title: "Chapter 1: Down the Rabbit Hole",
                htmlContent:
                    "<p>Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do. Once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it.</p><p>'And what is the use of a book,' thought Alice, 'without pictures or conversations?'</p>",
                order: 1
            )

            let chapter2 = Chapter(
                id: "ch2",
                title: "Chapter 2: The Pool of Tears",
                htmlContent:
                    "<p>'Curiouser and curiouser!' cried Alice (she was so much surprised, that for the moment she quite forgot how to speak good English). 'Now I'm opening out like the largest telescope that ever was! Good-bye, feet!'</p>",
                order: 2
            )

            sampleBook.chapters = [chapter1, chapter2]

            modelContext.insert(sampleBook)
            modelContext.insert(chapter1)
            modelContext.insert(chapter2)
        }
    }

    private func deleteBooks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(books[index])
            }
        }
    }
}

#Preview {
    let themeManager = ThemeManager.preview()
    return ContentView()
        .modelContainer(for: Book.self, inMemory: true)
        .environmentObject(themeManager)
        .environment(\.theme, themeManager.currentTheme)
}
