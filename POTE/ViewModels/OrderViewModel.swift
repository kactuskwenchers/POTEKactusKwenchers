import Foundation
import Combine

@MainActor
class OrderViewModel: ObservableObject {
    @Published var orderItems: [OrderItem] = []
    @Published var total: Double = 0.0
    @Published var orderNumber: Int?
    private var cancellables = Set<AnyCancellable>()
    private static var lastOrderNumber: Int = 0 // Persist this in production
    
    func addItem(_ menuItem: MenuItem) {
        if let index = orderItems.firstIndex(where: { $0.itemId == menuItem.id }) {
            orderItems[index].quantity += 1
        } else {
            orderItems.append(OrderItem(itemId: menuItem.id, quantity: 1))
        }
        calculateTotal()
    }
    
    func calculateTotal() {
        total = orderItems.reduce(0.0) { total, item in
            let price = MenuViewModel.shared.getMenuItem(forId: item.itemId)?.price ?? 0.0
            return total + (price * Double(item.quantity))
        }
    }
    
    func saveOrder(cashierId: String) async throws {
        // Auto-generate order number
        OrderViewModel.lastOrderNumber += 1
        let orderNumber = OrderViewModel.lastOrderNumber
        self.orderNumber = orderNumber
        
        let order = Order(
            id: UUID().uuidString,
            items: orderItems,
            total: total,
            status: "Pending",
            timestamp: Date(),
            cashierId: cashierId,
            orderNumber: orderNumber
        )
        print("OrderViewModel: Saving order with total: \(order.total), orderNumber: \(orderNumber)")
        try await FirebaseService.shared.saveOrder(order)
        // Do not reset here; reset after payment
    }
    
    func resetOrder() {
        orderItems.removeAll()
        total = 0.0
        orderNumber = nil
    }
}
