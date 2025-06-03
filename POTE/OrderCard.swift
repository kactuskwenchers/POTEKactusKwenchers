import SwiftUI

struct OrderCard: View {
    let order: Order
    let menuViewModel: MenuViewModel
    let onStatusChange: ((String) -> Void)?

    init(order: Order, menuViewModel: MenuViewModel, onStatusChange: ((String) -> Void)? = nil) {
        self.order = order
        self.menuViewModel = menuViewModel
        self.onStatusChange = onStatusChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Use order.id instead of orderNumber, display last 8 characters for brevity
                Text("Order #\(String(order.id.suffix(8)))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Text(order.status)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(order.status == "Held" ? .orange : .gray)
            }
            Text("Ongoing: \(Int(Date().timeIntervalSince(order.timestamp)/60)) Min")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
            ForEach(order.items, id: \.itemId) { item in
                Text("• \(menuViewModel.getItemName(forId: item.itemId)) x\(item.quantity)")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black)
            }
            Text("Total: $\(String(format: "%.2f", order.total))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
            if onStatusChange != nil {
                HStack(spacing: 8) {
                    Button(action: {
                        let newStatus = order.status == "Pending" ? "Held" : "Pending"
                        onStatusChange?(newStatus)
                    }) {
                        Text(order.status == "Pending" ? "Hold Order" : "Unhold Order")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(order.status == "Pending" ? Color.orange : Color.gray)
                            .cornerRadius(8)
                    }
                    Button(action: {
                        onStatusChange?("Completed")
                    }) {
                        Text("Order Done")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color(hex: "#2E7D32"))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct OrderCard_Previews: PreviewProvider {
    static var previews: some View {
        OrderCard(
            order: Order(
                id: UUID().uuidString,
                items: [OrderItem(itemId: "item2", quantity: 1)],
                total: 8.99,
                status: "Pending",
                timestamp: Date(),
                cashierId: "test_cashier"
            ),
            menuViewModel: MenuViewModel.shared
        )
        .environmentObject(MenuViewModel.shared)
        .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
