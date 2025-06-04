import Foundation
import Combine
import FirebaseFirestore

@MainActor
class KDSViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var errorMessage: String?
    public let categoryFilter: String
    private var stationId: String?
    private var listener: ListenerRegistration?

    init(categoryFilter: String, stationId: String? = nil) {
        self.categoryFilter = categoryFilter
        self.stationId = stationId
        setupOrdersListener()
    }

    deinit {
        listener?.remove()
    }

    func setStationId(_ newStationId: String?) {
        self.stationId = newStationId
        listener?.remove()
        setupOrdersListener()
    }

    private func setupOrdersListener() {
        let db = Firestore.firestore()
        var query = db.collection("orders")
            .whereField("status", in: ["Pending", "Held"])

        if let stationId = stationId {
            query = query.whereField("stationId", isEqualTo: stationId)
        }

        listener = query.addSnapshotListener { [weak self] snapshot, error in
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
                    let filteredItems = order.items.filter { item in
                        guard let menuItem = MenuViewModel.shared.getMenuItem(forId: item.itemId) else {
                            print("KDSViewModel: Item \(item.itemId) (name: \(MenuViewModel.shared.getItemName(forId: item.itemId))) not found in menu")
                            return false
                        }
                        let category = menuItem.category
                        print("KDSViewModel: Item \(item.itemId) (name: \(menuItem.name)) category '\(category)' matches filter '\(self.categoryFilter)'")
                        return category == self.categoryFilter
                    }
                    guard !filteredItems.isEmpty else { return nil }
                    return Order(
                        id: order.id,
                        items: filteredItems,
                        total: order.total,
                        status: order.status,
                        timestamp: order.timestamp,
                        cashierId: order.cashierId,
                        stationId: order.stationId,
                        priority: order.priority
                    )
                } catch {
                    print("KDSViewModel: Error decoding order \(document.documentID): \(error)")
                    return nil
                }
            }.sorted { lhs, rhs in
                let lhsPriority = lhs.priority == "Rush" ? 1 : 0
                let rhsPriority = rhs.priority == "Rush" ? 1 : 0
                if lhsPriority != rhsPriority {
                    return lhsPriority > rhsPriority
                }
                return lhs.timestamp < rhs.timestamp
            }
            print("KDSViewModel: Fetched \(self.orders.count) orders for category '\(self.categoryFilter)' station '\(self.stationId ?? "all")'")
        }
    }

    func updateOrderStatus(orderId: String, newStatus: String) async throws {
        let db = Firestore.firestore()
        let orderRef = db.collection("orders").document(orderId)
        try await orderRef.updateData(["status": newStatus])
        print("KDSViewModel: Updated order \(orderId) to status '\(newStatus)'")
    }
}
