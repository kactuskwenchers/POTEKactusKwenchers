import Foundation
import Combine

@MainActor
class OrderViewModel: ObservableObject {
    @Published var orderItems: [OrderItem] = []
    @Published var total: Double = 0.0
    @Published var productTotal: Double = 0.0 // Subtotal before tax
    @Published var taxAmount: Double = 0.0 // Tax amount
    @Published var orderNumber: Int?
    @Published var taxRate: Double = UserDefaults.standard.double(forKey: "selectedTaxRate") / 100 // Load from UserDefaults
    private var cancellables = Set<AnyCancellable>()
    
    // Initialize with saved tax rate
    init() {
        if let savedRate = UserDefaults.standard.object(forKey: "selectedTaxRate") as? Double {
            taxRate = savedRate / 100 // Convert percentage to decimal
        } else {
            taxRate = 0.0 // Default to 0% if no rate is set
        }
    }
    
    func addItem(_ menuItem: MenuItem) {
        if let index = orderItems.firstIndex(where: { $0.itemId == menuItem.id }) {
            orderItems[index].quantity += 1
        } else {
            orderItems.append(OrderItem(itemId: menuItem.id, quantity: 1))
        }
        calculateTotal()
    }
    
    func calculateTotal() {
        productTotal = orderItems.reduce(0.0) { total, item in
            let price = MenuViewModel.shared.getMenuItem(forId: item.itemId)?.price ?? 0.0
            return total + (price * Double(item.quantity))
        }
        taxAmount = productTotal * taxRate
        total = productTotal + taxAmount
    }
    
    func setTaxRate(_ rate: Double) {
        taxRate = rate
        calculateTotal()
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
        productTotal = 0.0
        taxAmount = 0.0
        total = 0.0
        orderNumber = nil
    }
}
