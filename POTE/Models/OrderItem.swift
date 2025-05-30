import SwiftUI
import Foundation

struct OrderItem: Codable, Equatable {
    let itemId: String
    var quantity: Int
    
    // Codable keys
    enum CodingKeys: String, CodingKey {
        case itemId
        case quantity
    }
}
