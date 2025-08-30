//
//  Models.swift
//  Dobi
//
//  Created by Kevin Wijaya on 8/30/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Book {
    var id: UUID
    var title: String
    var author: String
    var filePath: URL
    var coverImagePath: URL?
    var dateAdded: Date
    var lastOpened: Date?
    var fileSize: Int64

    @Relationship(deleteRule: .cascade)
    var chapters: [Chapter] = []

    @Relationship(deleteRule: .cascade)
    var readingProgress: ReadingProgress?

    init(title: String, author: String, filePath: URL) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.filePath = filePath
        self.dateAdded = Date()
        self.fileSize = 0
    }
}

@Model
final class Chapter {
    var id: String
    var title: String
    var htmlContent: String
    var cssStyles: String
    var order: Int
    var wordCount: Int

    init(id: String, title: String, htmlContent: String, order: Int) {
        self.id = id
        self.title = title
        self.htmlContent = htmlContent
        self.cssStyles = ""
        self.order = order
        self.wordCount = htmlContent.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
}

@Model
final class ReadingProgress {
    var currentChapter: String
    var currentPosition: Double // 0.0 to 1.0
    var timeSpent: TimeInterval
    var lastRead: Date

    @Relationship(deleteRule: .cascade)
    var bookmarks: [Bookmark] = []

    @Relationship(deleteRule: .cascade)
    var highlights: [Highlight] = []

    @Relationship(deleteRule: .cascade)
    var notes: [Note] = []

    init(currentChapter: String = "", currentPosition: Double = 0.0) {
        self.currentChapter = currentChapter
        self.currentPosition = currentPosition
        self.timeSpent = 0
        self.lastRead = Date()
    }
}

@Model
final class Bookmark {
    var id: UUID
    var chapterID: String
    var position: Double
    var title: String
    var dateCreated: Date

    init(chapterID: String, position: Double, title: String) {
        self.id = UUID()
        self.chapterID = chapterID
        self.position = position
        self.title = title
        self.dateCreated = Date()
    }
}

@Model
final class Highlight {
    var id: UUID
    var chapterID: String
    var startPosition: Double
    var endPosition: Double
    var text: String
    var color: String
    var dateCreated: Date

    init(chapterID: String, startPosition: Double, endPosition: Double, text: String, color: String = "yellow") {
        self.id = UUID()
        self.chapterID = chapterID
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.text = text
        self.color = color
        self.dateCreated = Date()
    }
}

@Model
final class Note {
    var id: UUID
    var chapterID: String
    var position: Double
    var text: String
    var dateCreated: Date
    var dateModified: Date

    init(chapterID: String, position: Double, text: String) {
        self.id = UUID()
        self.chapterID = chapterID
        self.position = position
        self.text = text
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}

@Model
final class UserPreferences {
    var fontSize: Double
    var fontFamily: String
    var lineSpacing: Double
    var marginSize: Double
    var colorTheme: String
    var brightnessLevel: Double
    var animationSpeed: Double
    var themeSchedule: String
    var lightThemeStartHour: Int
    var lightThemeStartMinute: Int
    var darkThemeStartHour: Int
    var darkThemeStartMinute: Int
    var ambientLightThreshold: Double

    init() {
        self.fontSize = 16.0
        self.fontFamily = "System"
        self.lineSpacing = 1.2
        self.marginSize = 20.0
        self.colorTheme = "light"
        self.brightnessLevel = 1.0
        self.animationSpeed = 0.3
        self.themeSchedule = "system"
        self.lightThemeStartHour = 7
        self.lightThemeStartMinute = 0
        self.darkThemeStartHour = 19
        self.darkThemeStartMinute = 0
        self.ambientLightThreshold = 0.5
    }
}
