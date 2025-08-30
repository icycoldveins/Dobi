//
//  Item.swift
//  Dobi
//
//  Created by Kevin Wijaya on 8/30/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
