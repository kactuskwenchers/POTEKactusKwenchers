import Foundation
import Combine

@MainActor
class OrderViewModel: ObservableObject {
    @Published var orderItems: [OrderItem] = []
    @Published var total: Double = 0.0
    @Published var orderNumber: Int?
    private var cancellables = Set<AnyCancellable>()
    
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
    
    func saveOrder(cashierId: String, paymentType: String, paymentId: String?) async throws {
        guard let orderNumber = orderNumber else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Order number not set"])
        }
        
        print("OrderViewModel: Received cashierId: \(cashierId) for saving order")
        let order = Order(
            id: UUID().uuidString,
            items: orderItems,
            total: total,
            status: "Completed",
            timestamp: Date(),
            cashierId: cashierId,
            orderNumber: orderNumber,
            paymentId: paymentId,
            paymentType: paymentType
        )
        print("OrderViewModel: Saving order with total: \(order.total), orderNumber: \(orderNumber), paymentType: \(paymentType), cashierId: \(order.cashierId)")
        try await FirebaseService.shared.saveOrder(order)
    }
    
    func resetOrder() {
        orderItems.removeAll()
        total = 0.0
        orderNumber = nil
    }
}
