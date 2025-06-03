import SwiftUI

struct MenuView: View {
    @EnvironmentObject var viewModel: MenuViewModel
    @StateObject private var orderViewModel = OrderViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var navigateToPOS: Bool
    @State private var buttonTappedId: String?
    @State private var showOrderNumberPrompt = false
    @State private var showPaymentView = false
    @State private var orderNumberInput = ""
    @State private var isToGo = false
    @State private var showTransactionSearch = false
    @State private var showLogoutConfirmation = false
    @State private var selectedCategory = "Kickers"
    
    private let categories = ["Kickers", "Kolas", "Kwenchers", "Toast"]
    
    var filteredItems: [MenuItem] {
        viewModel.items.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header with Employee Details
                    HStack {
                        VStack(alignment: .leading) {
                            Text("POTE POS")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "#2E7D32"))
                            if let cashier = authViewModel.cashier {
                                Text("\(cashier.firstName ?? "Unknown") \(cashier.lastName ?? "Employee") - \(cashier.role.capitalized)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            } else {
                                Text("No Cashier Logged In")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    
                    HStack(spacing: 0) {
                        // Left Sidebar: Order
                        VStack(spacing: 0) {
                            // Order Items
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    if orderViewModel.orderItems.isEmpty {
                                        Text("No items in order")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.gray)
                                            .padding(.top, 20)
                                    } else {
                                        ForEach(orderViewModel.orderItems.indices, id: \.self) { index in
                                            let orderItem = orderViewModel.orderItems[index]
                                            OrderItemRow(
                                                orderItem: orderItem,
                                                itemName: viewModel.getItemName(forId: orderItem.itemId),
                                                isTapped: buttonTappedId == orderItem.itemId,
                                                onRemove: {
                                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                                        buttonTappedId = orderItem.itemId
                                                    }
                                                    orderViewModel.orderItems[index].quantity -= 1
                                                    if orderViewModel.orderItems[index].quantity <= 0 {
                                                        orderViewModel.orderItems.remove(at: index)
                                                    }
                                                    orderViewModel.calculateTotal()
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                        buttonTappedId = nil
                                                    }
                                                }
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                                .padding(.vertical, 16)
                            }
                            
                            // Total and Action Buttons
                            VStack(spacing: 10) {
                                HStack {
                                    Text("Total:")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", orderViewModel.total))")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                
                                if !orderViewModel.orderItems.isEmpty {
                                    HStack(spacing: 10) {
                                        Button(action: {
                                            isToGo = true
                                            showOrderNumberPrompt = true
                                        }) {
                                            Text("To Go")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(.vertical, 15)
                                                .padding(.horizontal, 20)
                                                .frame(maxWidth: .infinity, minHeight: 60)
                                                .background(Color(hex: "#0288D1"))
                                                .cornerRadius(12)
                                        }
                                        
                                        Button(action: {
                                            isToGo = false
                                            showOrderNumberPrompt = true
                                        }) {
                                            Text("Dine In")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(.vertical, 15)
                                                .padding(.horizontal, 20)
                                                .frame(maxWidth: .infinity, minHeight: 60)
                                                .background(Color(hex: "#2E7D32"))
                                                .cornerRadius(12)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 10)
                                }
                            }
                            .background(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: -2)
                        }
                        .frame(width: geometry.size.width * 0.25)
                        .background(Color.white)
                        
                        // Main Content: Categories and Menu Items
                        VStack(spacing: 0) {
                            // Categories Bar
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(categories, id: \.self) { category in
                                        Button(action: {
                                            selectedCategory = category
                                        }) {
                                            Text(category)
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(selectedCategory == category ? .white : .gray)
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 20)
                                                .background(selectedCategory == category ? Color(hex: "#2E7D32") : Color.clear)
                                                .cornerRadius(10)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                            .background(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
                            
                            // Menu Items Grid
                            ScrollView {
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 24),
                                        GridItem(.flexible(), spacing: 24),
                                        GridItem(.flexible(), spacing: 24)
                                    ],
                                    spacing: 24
                                ) {
                                    ForEach(filteredItems) { item in
                                        MenuItemCard(
                                            item: item,
                                            isTapped: buttonTappedId == item.id,
                                            onAdd: {
                                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                                    buttonTappedId = item.id
                                                }
                                                orderViewModel.addItem(item)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                    buttonTappedId = nil
                                                }
                                            }
                                        )
                                        .frame(minHeight: 240)
                                    }
                                }
                                .padding(.horizontal, max(16, geometry.size.width * 0.02))
                                .padding(.vertical, 24)
                            }
                            
                            // Bottom Bar with Additional Actions
                            HStack(spacing: 10) {
                                Button(action: {
                                    print("MenuView: Back button tapped, dismissing to LandingView")
                                    navigateToPOS = false
                                    dismiss()
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
                                    .frame(minHeight: 60)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    showTransactionSearch = true
                                }) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 24))
                                        Text("Search Orders")
                                            .font(.system(size: 20, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color(hex: "#0288D1"))
                                    .cornerRadius(12)
                                    .frame(minHeight: 60)
                                }
                                
                                Button(action: {
                                    showLogoutConfirmation = true
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.left.circle.fill")
                                            .font(.system(size: 24))
                                        Text("Cashier Logout")
                                            .font(.system(size: 20, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color(hex: "#FF6200"))
                                    .cornerRadius(12)
                                    .frame(minHeight: 60)
                                }
                            }
                            .padding(.horizontal, max(16, geometry.size.width * 0.02))
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: -2)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Confirm Cashier Logout", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                print("MenuView: Logging out cashier and dismissing to LandingView")
                authViewModel.logoutCashier()
                navigateToPOS = false
                dismiss()
            }
        } message: {
            Text("Are you sure you want to log out as cashier?")
        }
        .sheet(isPresented: $showOrderNumberPrompt) {
            OrderNumberPromptView(
                orderNumberInput: $orderNumberInput,
                onConfirm: {
                    if let orderNumber = Int(orderNumberInput) {
                        orderViewModel.orderNumber = orderNumber
                        showOrderNumberPrompt = false
                        showPaymentView = true
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
                amount: Int(orderViewModel.total * 100),
                orderViewModel: orderViewModel
            )
            .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showTransactionSearch) {
            TransactionSearchView()
                .environmentObject(authViewModel)
        }
        .onChange(of: navigateToPOS) { newValue in
            print("MenuView: navigateToPOS changed to \(newValue)")
        }
    }
}

struct MenuItemCard: View {
    let item: MenuItem
    let isTapped: Bool
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Placeholder image
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#F5F5F5"))
                .frame(height: 160)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .font(.system(size: 48))
                )
            
            Text(item.name)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text("$\(String(format: "%.2f", item.price))")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
            
            Button(action: onAdd) {
                Text("Add")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color(hex: "#2E7D32"))
                    .cornerRadius(10)
                    .scaleEffect(isTapped ? 0.9 : 1.0)
                    .frame(minHeight: 48)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MenuView_Previews: PreviewProvider {
    @State static var navigateToPOS = false
    
    static var previews: some View {
        MenuView(navigateToPOS: $navigateToPOS)
            .environmentObject(MenuViewModel.shared)
            .environmentObject(AuthViewModel())
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
