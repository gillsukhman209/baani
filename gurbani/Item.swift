//
//  Item.swift
//  gurbani
//
//  Created by Sukhman Singh on 3/29/26.
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
