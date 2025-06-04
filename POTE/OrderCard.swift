import SwiftUI
import AVFoundation

struct OrderCard: View {
    let order: Order
    let menuViewModel: MenuViewModel
    let onStatusChange: ((String) -> Void)?
    @State private var showNewOrderAnimation = false
    @State private var borderColor: Color = .clear
    @State private var isHighlighted = false
    @State private var isExpanded = false

    init(order: Order, menuViewModel: MenuViewModel, onStatusChange: ((String) -> Void)? = nil) {
        self.order = order
        self.menuViewModel = menuViewModel
        self.onStatusChange = onStatusChange
        self._showNewOrderAnimation = State(initialValue: true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Row
            HStack {
                Text(LocalizedStringKey("Order #\(String(order.id.suffix(8)))"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                if let stationId = order.stationId {
                    Text(LocalizedStringKey(stationId))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                Spacer()
                Text(LocalizedStringKey(order.status))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(order.status == "Held" ? .orange : .gray)
            }

            // Priority Badge
            if order.priority == "Rush" {
                Text(LocalizedStringKey("Rush Order"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }

            // Order Age with Color Coding
            let ageInMinutes = Int(Date().timeIntervalSince(order.timestamp) / 60)
            let ageColor: Color = ageInMinutes < 5 ? .green : (ageInMinutes < 10 ? .yellow : .red)
            Text(LocalizedStringKey("Ongoing: \(ageInMinutes) Min"))
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(ageColor)

            // Items List (Expandable)
            VStack(alignment: .leading, spacing: 6) {
                if isExpanded || order.items.count <= 3 {
                    ForEach(order.items, id: \.itemId) { item in
                        Text("• \(menuViewModel.getItemName(forId: item.itemId)) x\(item.quantity)")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.black)
                    }
                } else {
                    ForEach(order.items.prefix(3), id: \.itemId) { item in
                        Text("• \(menuViewModel.getItemName(forId: item.itemId)) x\(item.quantity)")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.black)
                    }
                    Text("+\(order.items.count - 3) more items")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }

            // Total
            Text(LocalizedStringKey("Total: $\(String(format: "%.2f", order.total))"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.black)

            // Action Buttons
            if onStatusChange != nil {
                HStack(spacing: 16) {
                    Button(action: {
                        let newStatus = order.status == "Pending" ? "Held" : "Pending"
                        onStatusChange?(newStatus)
                    }) {
                        Text(LocalizedStringKey(order.status == "Pending" ? "Hold Order" : "Unhold Order"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(minWidth: 130, minHeight: 70)
                            .background(order.status == "Pending" ? Color.orange : Color.gray)
                            .cornerRadius(12)
                    }
                    .padding(.vertical, 4)

                    Button(action: {
                        onStatusChange?("Completed")
                    }) {
                        Text(LocalizedStringKey("Order Done"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(minWidth: 130, minHeight: 70)
                            .background(Color(hex: "#2E7D32"))
                            .cornerRadius(12)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.top, 12)
            }
        }
        .padding(24)
        .frame(minWidth: 320, maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(order.priority == "Rush" ? 0.3 : 0.1), radius: order.priority == "Rush" ? 8 : 4, x: 0, y: order.priority == "Rush" ? 4 : 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.yellow : borderColor, lineWidth: isHighlighted ? 4 : 2)
        )
        .onAppear {
            // Trigger animation and sound for new orders
            if showNewOrderAnimation {
                withAnimation(.easeInOut(duration: 0.5).repeatCount(3)) {
                    borderColor = .green
                }
                playNewOrderSound()
                showNewOrderAnimation = false
            }

            // Delayed order alert
            let ageInSeconds = Date().timeIntervalSince(order.timestamp)
            if ageInSeconds > 600 { // 10 minutes
                withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                    borderColor = .red
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 { // Swipe right to complete
                        onStatusChange?("Completed")
                    } else if value.translation.width < -100 { // Swipe left to hold
                        let newStatus = order.status == "Pending" ? "Held" : "Pending"
                        onStatusChange?(newStatus)
                    }
                }
        )
        .onTapGesture(count: 2) {
            isHighlighted.toggle()
        }
    }

    private func playNewOrderSound() {
        guard let url = Bundle.main.url(forResource: "alert", withExtension: "mp3") else {
            print("OrderCard: Alert sound file not found")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
        } catch {
            print("OrderCard: Error playing sound: \(error)")
        }
    }
}

struct OrderCard_Previews: PreviewProvider {
    static var previews: some View {
        OrderCard(
            order: Order(
                id: UUID().uuidString,
                items: [
                    OrderItem(itemId: "item1", quantity: 1),
                    OrderItem(itemId: "item2", quantity: 2),
                    OrderItem(itemId: "item3", quantity: 1),
                    OrderItem(itemId: "item4", quantity: 3)
                ],
                total: 8.99,
                status: "Pending",
                timestamp: Date(),
                cashierId: "test_cashier",
                stationId: "drink_station_1",
                priority: "Rush"
            ),
            menuViewModel: MenuViewModel.shared
        )
        .environmentObject(MenuViewModel.shared)
        .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
