import SwiftUI

struct OrderView: View {
    @ObservedObject var viewModel: OrderViewModel
    @EnvironmentObject var menuViewModel: MenuViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var navigateToLanding: Bool // To pop back to LandingView
    @State private var isLogoVisible = false
    @State private var buttonTappedId: String?
    @State private var showPaymentView = false
    @State private var showOrderNumberPrompt = false
    @State private var orderNumberInput = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HeaderView(isLogoVisible: $isLogoVisible)
                    OrderItemsList(
                        orderItems: $viewModel.orderItems,
                        total: $viewModel.total,
                        menuViewModel: menuViewModel,
                        buttonTappedId: $buttonTappedId
                    )
                    BottomBar(
                        viewModel: viewModel,
                        navigateToLanding: $navigateToLanding,
                        showPaymentView: $showPaymentView,
                        showOrderNumberPrompt: $showOrderNumberPrompt,
                        dismiss: dismiss
                    )
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showOrderNumberPrompt) {
                OrderNumberPromptView(
                    orderNumberInput: $orderNumberInput,
                    onConfirm: {
                        if let orderNumber = Int(orderNumberInput) {
                            viewModel.orderNumber = orderNumber
                            Task {
                                do {
                                    try await viewModel.saveOrder(cashierId: "test_cashier")
                                    showOrderNumberPrompt = false
                                    showPaymentView = true
                                } catch {
                                    print("Failed to save order: \(error)")
                                }
                            }
                        }
                    },
                    onCancel: {
                        showOrderNumberPrompt = false
                    }
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showPaymentView) {
                PaymentView(
                    amount: Int(viewModel.total * 100), // Convert to cents
                    orderViewModel: viewModel
                )
                .environmentObject(menuViewModel)
            }
        }
    }
}

// MARK: - Subviews

struct HeaderView: View {
    @Binding var isLogoVisible: Bool

    var body: some View {
        HStack {
            Image("POTEIconSmall")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(Color(hex: "#00FF00"))
            Text("POTE Order")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#2E7D32"))
            Spacer()
        }
        .padding(.top, 24)
        .padding(.horizontal, 32)
        .opacity(isLogoVisible ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.3), value: isLogoVisible)
        .onAppear { isLogoVisible = true }
    }
}

struct OrderItemsList: View {
    @Binding var orderItems: [OrderItem]
    @Binding var total: Double
    @ObservedObject var menuViewModel: MenuViewModel
    @Binding var buttonTappedId: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(orderItems.indices, id: \.self) { index in
                    let orderItem = orderItems[index]
                    OrderItemRow(
                        orderItem: orderItem,
                        itemName: menuViewModel.getItemName(forId: orderItem.itemId),
                        isTapped: buttonTappedId == orderItem.itemId,
                        onRemove: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                buttonTappedId = orderItem.itemId
                            }
                            orderItems[index].quantity -= 1
                            if orderItems[index].quantity <= 0 {
                                orderItems.remove(at: index)
                            }
                            total = orderItems.reduce(0.0) { total, item in
                                let price = menuViewModel.getMenuItem(forId: item.itemId)?.price ?? 0.0
                                return total + (price * Double(item.quantity))
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                buttonTappedId = nil
                            }
                        }
                    )
                    .padding(.horizontal, 32)
                }
                if orderItems.isEmpty {
                    Text("No items in order")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                }
            }
            .padding(.vertical, 16)
        }
    }
}

struct BottomBar: View {
    @ObservedObject var viewModel: OrderViewModel
    @Binding var navigateToLanding: Bool
    @Binding var showPaymentView: Bool
    @Binding var showOrderNumberPrompt: Bool
    let dismiss: DismissAction

    var body: some View {
        VStack(spacing: 16) {
            // Total
            HStack {
                Text("Total:")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("$\(String(format: "%.2f", viewModel.total))")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 32)
            
            // Action Buttons
            HStack(spacing: 24) {
                Button(action: {
                    navigateToLanding = true // Pop back to LandingView
                }) {
                    HStack {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 24))
                        Text("Back")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
                    .frame(minHeight: 64)
                }

                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                        Text("Cancel")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(hex: "#FF6200"))
                    .cornerRadius(12)
                    .frame(minHeight: 64)
                }
                
                Spacer()
                
                Button(action: {
                    if viewModel.orderItems.isEmpty {
                        dismiss()
                    } else {
                        showOrderNumberPrompt = true
                    }
                }) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 24))
                        Text("Pay Now")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#2E7D32"), Color(hex: "#388E3C")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .frame(minHeight: 64)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
        }
        .background(Color.white)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: -2)
    }
}

struct OrderItemRow: View {
    let orderItem: OrderItem
    let itemName: String
    let isTapped: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text("\(itemName) x\(orderItem.quantity)")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.primary)
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#FF6200"))
                    .scaleEffect(isTapped ? 0.9 : 1.0)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct OrderNumberPromptView: View {
    @Binding var orderNumberInput: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Enter Order Number")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            TextField("Order Number", text: $orderNumberInput)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .padding(.horizontal, 32)
                .frame(height: 48)
            
            HStack(spacing: 24) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(hex: "#FF6200"))
                        .cornerRadius(12)
                }
                
                Button(action: onConfirm) {
                    Text("Confirm")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(hex: "#2E7D32"))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct OrderView_Previews: PreviewProvider {
    @State static var navigateToLanding = false

    static var previews: some View {
        OrderView(viewModel: OrderViewModel(), navigateToLanding: $navigateToLanding)
            .environmentObject(MenuViewModel.shared)
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
