//
//  User.swift
//  POTE
//
//  Created by Kacrtus Kwenchers on 5/30/25.
//


import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let role: String
}
