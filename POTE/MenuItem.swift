//
//  MenuItem.swift
//  POTE
//
//  Created by Kacrtus Kwenchers on 5/30/25.
//


import Foundation

struct MenuItem: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let price: Double
    let category: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case price
        case category
    }
    
    static func ==(lhs: MenuItem, rhs: MenuItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.price == rhs.price &&
               lhs.category == rhs.category
    }
}
