//
//  MenuViewModel.swift
//  POTE
//
//  Created by Kacrtus Kwenchers on 5/30/25.
//


import Foundation
import Combine

@MainActor
class MenuViewModel: ObservableObject {
    static let shared = MenuViewModel()
    @Published var items: [MenuItem] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    private var itemDictionary: [String: MenuItem] = [:]
    private var hasFetchedItems: Bool = false
    
    private init() {}
    
    func fetchItems() async {
        if hasFetchedItems {
            print("MenuViewModel: Items already fetched, skipping fetch")
            return
        }
        isLoading = true
        do {
            print("MenuViewModel: Fetching menu items")
            let fetchedItems = try await FirebaseService.shared.fetchItems()
            items = fetchedItems
            itemDictionary = Dictionary(uniqueKeysWithValues: fetchedItems.map { ($0.id, $0) })
            errorMessage = nil
            hasFetchedItems = true
            print("MenuViewModel: Fetched \(items.count) menu items")
            print("MenuViewModel: Item dictionary keys: \(itemDictionary.keys)")
        } catch {
            errorMessage = error.localizedDescription
            print("MenuViewModel: Fetch error: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func getItemName(forId id: String) -> String {
        itemDictionary[id]?.name ?? "Unknown Item"
    }
    
    func getMenuItem(forId id: String) -> MenuItem? {
        return itemDictionary[id]
    }
}
