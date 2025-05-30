//
//  KDSView.swift
//  POTE
//
//  Created by Kacrtus Kwenchers on 5/31/25.
//
import SwiftUI
import FirebaseFirestore

struct KDSView: View {
    @StateObject private var viewModel: KDSViewModel
    @EnvironmentObject var menuViewModel: MenuViewModel
    @State private var isLogoVisible = false
    private let category: String

    init(category: String) {
        self.category = category
        self._viewModel = StateObject(wrappedValue: KDSViewModel(categoryFilter: category))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with POTE branding
                    HStack {
                        Image("POTEIconSmall")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .foregroundColor(Color(hex: "#00FF00"))
                        Text("POTE \(category) KDS")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "#2E7D32"))
                        Spacer()
                        Button(action: { /* TODO: Log out */ }) {
                            Text("Log Out")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                    .opacity(isLogoVisible ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: isLogoVisible)
                    .onAppear { isLogoVisible = true }
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.orders) { order in
                                OrderCard(
                                    order: order,
                                    menuViewModel: menuViewModel,
                                    onStatusChange: { newStatus in
                                        Task {
                                            do {
                                                try await viewModel.updateOrderStatus(orderId: order.id, newStatus: newStatus)
                                            } catch {
                                                print("Failed to update order status: \(error)")
                                            }
                                        }
                                    }
                                )
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.vertical, 16)
                        if viewModel.orders.isEmpty {
                            Text("No \(category) Orders")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct KDSView_Previews: PreviewProvider {
    static var previews: some View {
        KDSView(category: "Drink")
            .environmentObject(MenuViewModel.shared)
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)")))
    }
}
