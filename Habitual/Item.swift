//
//  Item.swift
//  Habitual
//
//  Created by Somila Somila on 2026/11/23.
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
