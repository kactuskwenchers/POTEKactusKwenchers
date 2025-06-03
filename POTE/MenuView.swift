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
    @State private var showSettingsPopup = false
    
    private let categories = ["Kickers", "Kolas", "Kwenchers", "Toast"]
    
    var filteredItems: [MenuItem] {
        viewModel.items.filter { $0.category == selectedCategory }
    }
    
    // Computed property for manager status
    private var isManager: Bool {
        authViewModel.cashier?.role.lowercased() == "manager"
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Use renamed MenuHeaderView
                    MenuHeaderView(
                        authViewModel: authViewModel,
                        isManager: isManager,
                        onSettingsTap: { showSettingsPopup = true }
                    )
                    
                    HStack(spacing: 0) {
                        OrderSidebarView(
                            orderViewModel: orderViewModel,
                            viewModel: viewModel,
                            buttonTappedId: $buttonTappedId,
                            isToGo: $isToGo,
                            showOrderNumberPrompt: $showOrderNumberPrompt,
                            geometry: geometry
                        )
                        
                        MenuContentView(
                            selectedCategory: $selectedCategory,
                            categories: categories,
                            filteredItems: filteredItems,
                            buttonTappedId: $buttonTappedId,
                            orderViewModel: orderViewModel,
                            navigateToPOS: $navigateToPOS,
                            showTransactionSearch: $showTransactionSearch,
                            showLogoutConfirmation: $showLogoutConfirmation,
                            dismiss: dismiss,
                            geometry: geometry
                        )
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
        .sheet(isPresented: $showSettingsPopup) {
            SettingsView()
                .environmentObject(orderViewModel) // Pass orderViewModel for tax rate
                .presentationDetents([.medium])
        }
        .onChange(of: navigateToPOS) { newValue in
            print("MenuView: navigateToPOS changed to \(newValue)")
        }
    }
}

// Header View for MenuView, renamed to avoid conflicts
struct MenuHeaderView: View {
    @ObservedObject var authViewModel: AuthViewModel
    let isManager: Bool
    let onSettingsTap: () -> Void
    
    var body: some View {
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
            Button(action: onSettingsTap) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isManager ? Color(hex: "#2E7D32") : .gray)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .disabled(!isManager)
            .accessibilityLabel(isManager ? "Settings" : "Settings, disabled for non-managers")
        }
        .padding(.top, 24)
        .padding(.horizontal, 16)
        .background(Color.white)
    }
}

// Extracted Order Sidebar View
struct OrderSidebarView: View {
    @ObservedObject var orderViewModel: OrderViewModel
    @ObservedObject var viewModel: MenuViewModel
    @Binding var buttonTappedId: String?
    @Binding var isToGo: Bool
    @Binding var showOrderNumberPrompt: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 0) {
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
    }
}

// Extracted Menu Content View
struct MenuContentView: View {
    @Binding var selectedCategory: String
    let categories: [String]
    let filteredItems: [MenuItem]
    @Binding var buttonTappedId: String?
    @ObservedObject var orderViewModel: OrderViewModel
    @Binding var navigateToPOS: Bool
    @Binding var showTransactionSearch: Bool
    @Binding var showLogoutConfirmation: Bool
    let dismiss: DismissAction
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 0) {
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

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var orderViewModel: OrderViewModel
    @State private var taxRates: [TaxRate] = []
    @State private var selectedCity: String = UserDefaults.standard.string(forKey: "selectedTaxCity") ?? ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("POS Settings")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            // Tax Rate Selector
            VStack(alignment: .leading, spacing: 10) {
                Text("Sales Tax Location")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                
                if isLoading {
                    ProgressView("Loading tax rates...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                } else if taxRates.isEmpty {
                    Text("No tax rates available")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                } else {
                    Picker("Select City", selection: $selectedCity) {
                        ForEach(taxRates) { taxRate in
                            Text("\(taxRate.city) (\(String(format: "%.1f", taxRate.totalRate))%)")
                                .tag(taxRate.city)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedCity) { newCity in
                        if let selectedTaxRate = taxRates.first(where: { $0.city == newCity }) {
                            orderViewModel.setTaxRate(selectedTaxRate.totalRate / 100) // Convert % to decimal
                            UserDefaults.standard.set(newCity, forKey: "selectedTaxCity")
                            UserDefaults.standard.set(selectedTaxRate.totalRate, forKey: "selectedTaxRate")
                            orderViewModel.calculateTotal() // Recalculate total with new tax
                        }
                    }
                    
                    if !selectedCity.isEmpty {
                        Text("Current Tax Rate: \(String(format: "%.1f", (orderViewModel.taxRate * 100)))%")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Text("Close")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color(hex: "#2E7D32"))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding()
        .task {
            // Fetch tax rates when SettingsView appears
            isLoading = true
            do {
                taxRates = try await FirebaseService.shared.fetchTaxRates()
                // Set initial tax rate if none selected
                if selectedCity.isEmpty, let firstTaxRate = taxRates.first {
                    selectedCity = firstTaxRate.city
                    orderViewModel.setTaxRate(firstTaxRate.totalRate / 100)
                    UserDefaults.standard.set(firstTaxRate.city, forKey: "selectedTaxCity")
                    UserDefaults.standard.set(firstTaxRate.totalRate, forKey: "selectedTaxRate")
                    orderViewModel.calculateTotal()
                }
                isLoading = false
            } catch {
                errorMessage = "Failed to load tax rates: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

struct MenuItemCard: View {
    let item: MenuItem
    let isTapped: Bool
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
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
            .environmentObject(MenuViewModel.shared) // Use shared instance
            .environmentObject(AuthViewModel())
            .environmentObject(OrderViewModel())
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
