import SwiftUI

struct MenuView: View {
    @EnvironmentObject var viewModel: MenuViewModel
    @StateObject private var orderViewModel = OrderViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    @State private var buttonTappedId: String?
    @State private var showOrderView = false
    @State private var showLogoutConfirmation = false
    @State private var navigateToLanding = false
    @State private var isLogoVisible = false
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header with POTE branding
                    HStack {
                        Image("POTEIconSmall")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .foregroundColor(Color(hex: "#00FF00"))
                        Text("POTE")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(hex: "#2E7D32"))
                        Spacer()
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 32)
                    .opacity(isLogoVisible ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: isLogoVisible)
                    .onAppear { isLogoVisible = true }
                    
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 24),
                                GridItem(.flexible(), spacing: 24),
                                GridItem(.flexible(), spacing: 24)
                            ],
                            spacing: 24
                        ) {
                            ForEach(viewModel.items) { item in
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
                        .padding(.horizontal, max(32, geometry.size.width * 0.05))
                        .padding(.vertical, 24)
                    }
                    
                    // Fixed bottom bar
                    HStack(spacing: 24) {
                        if !orderViewModel.orderItems.isEmpty {
                            Button(action: {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                    showOrderView = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "cart.fill")
                                        .font(.system(size: 24))
                                    Text("Cart (\(orderViewModel.orderItems.count))")
                                        .font(.system(size: 20, weight: .semibold))
                                    Spacer()
                                    Text("$\(String(format: "%.2f", orderViewModel.total))")
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
                        
                        Spacer()
                        
                        Button(action: {
                            showLogoutConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.left.circle.fill")
                                    .font(.system(size: 24))
                                Text("Logout")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(hex: "#FF6200"))
                            .cornerRadius(12)
                            .frame(minHeight: 64)
                        }
                    }
                    .padding(.horizontal, max(32, geometry.size.width * 0.05))
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: -2)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Confirm Logout", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                Task {
                    await authViewModel.logout()
                    if authViewModel.user == nil {
                        navigateToLanding = true
                    }
                }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .sheet(isPresented: $showOrderView) {
            OrderView(
                viewModel: orderViewModel,
                navigateToLanding: $navigateToLanding
            )
            .environmentObject(viewModel)
            .onChange(of: navigateToLanding) { newValue in
                if newValue {
                    showOrderView = false
                    navigateToLanding = false
                }
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
    static var previews: some View {
        MenuView()
            .environmentObject(MenuViewModel.shared)
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
