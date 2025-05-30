//
//  KDSViewModel.swift
//  POTE
//
//  Created by Kacrtus Kwenchers on 5/31/25.
//
import Foundation
import Combine
import FirebaseFirestore

@MainActor
class KDSViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var errorMessage: String?
    private let categoryFilter: String
    private var listener: ListenerRegistration?

    init(categoryFilter: String) {
        self.categoryFilter = categoryFilter
        setupOrdersListener()
    }

    deinit {
        listener?.remove()
    }

    private func setupOrdersListener() {
        let db = Firestore.firestore()
        listener = db.collection("orders")
            .whereField("status", in: ["Pending", "Held"])
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("KDSViewModel: Fetch error: \(error.localizedDescription)")
                    return
                }

                guard let snapshot = snapshot else {
                    self.errorMessage = "No data available"
                    return
                }

                self.orders = snapshot.documents.compactMap { document in
                    do {
                        let order = try document.data(as: Order.self)
                        // Filter items by category
                        let filteredItems = order.items.filter { item in
                            guard let menuItem = MenuViewModel.shared.getMenuItem(forId: item.itemId) else {
                                print("KDSViewModel: Item \(item.itemId) (name: \(MenuViewModel.shared.getItemName(forId: item.itemId))) not found in menu")
                                return false
                            }
                            let category = menuItem.category
                            print("KDSViewModel: Item \(item.itemId) (name: \(menuItem.name)) category '\(category)' matches filter '\(self.categoryFilter)'")
                            return category == self.categoryFilter
                        }
                        return filteredItems.isEmpty ? nil : Order(
                            id: order.id,
                            items: filteredItems,
                            total: order.total,
                            status: order.status,
                            timestamp: order.timestamp,
                            cashierId: order.cashierId,
                            orderNumber: order.orderNumber
                        )
                    } catch {
                        print("KDSViewModel: Error decoding order \(document.documentID): \(error)")
                        return nil
                    }
                }.sorted { $0.timestamp < $1.timestamp }
                print("KDSViewModel: Fetched \(self.orders.count) orders")
            }
    }

    func updateOrderStatus(orderId: String, newStatus: String) async throws {
        let db = Firestore.firestore()
        let orderRef = db.collection("orders").document(orderId)
        try await orderRef.updateData(["status": newStatus])
        print("KDSViewModel: Updated order \(orderId) to status '\(newStatus)'")
    }
}
