import SwiftUI

struct OrderView: View {
    @ObservedObject var viewModel: OrderViewModel
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var navigateToLanding: Bool
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
                                    let cashierId = authViewModel.cashier?.employeeId ?? "unknown"
                                    print("OrderView: Saving order with cashierId: \(cashierId) for Pending payment")
                                    try await viewModel.saveOrder(
                                        cashierId: cashierId,
                                        paymentType: "Pending",
                                        paymentId: nil
                                    )
                                    showOrderNumberPrompt = false
                                    showPaymentView = true
                                } catch {
                                    print("OrderView: Failed to save order: \(error)")
                                }
                            }
                        }
                    },
                    onCancel: {
                        showOrderNumberPrompt = false
                    }
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showPaymentView) {
                PaymentView(
                    amount: Int(viewModel.total * 100),
                    orderViewModel: viewModel
                )
                .environmentObject(menuViewModel)
                .environmentObject(authViewModel)
            }
        }
    }
}

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
                    navigateToLanding = true
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

struct OrderNumberPromptView: View {
    @Binding var orderNumberInput: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 15) {
                // Title
                Text("Enter Order Number")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: "#2E7D32"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                
                // Display Entered Number
                Text(orderNumberInput.isEmpty ? "00" : orderNumberInput)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: min(geometry.size.width * 0.6, 300), height: 80)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 40)
                
                // Numerical Keypad
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ], spacing: 2) {
                    ForEach(1..<10) { number in
                        Button(action: {
                            if orderNumberInput.count < 2 {
                                orderNumberInput += String(number)
                            }
                        }) {
                            Text("\(number)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 90, height: 90)
                                .background(Color.gray)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                        }
                    }
                    Button(action: {
                        orderNumberInput = ""
                    }) {
                        Text("Clear")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 90, height: 90)
                            .background(Color(hex: "#FF6200"))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                    }
                    Button(action: {
                        if orderNumberInput.count < 2 {
                            orderNumberInput += "0"
                        }
                    }) {
                        Text("0")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 90, height: 90)
                            .background(Color.gray)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, max(20, geometry.size.width * 0.05))
                
                // Action Buttons
                HStack(spacing: 10) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(Color(hex: "#FF6200"))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    Button(action: onConfirm) {
                        Text("Confirm")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(Color(hex: "#2E7D32"))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, max(20, geometry.size.width * 0.05))
                .padding(.vertical, 10)
                
                Spacer()
            }
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
    }
}

struct OrderView_Previews: PreviewProvider {
    @State static var navigateToLanding = false

    static var previews: some View {
        OrderView(viewModel: OrderViewModel(), navigateToLanding: $navigateToLanding)
            .environmentObject(MenuViewModel.shared)
            .environmentObject(AuthViewModel())
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
