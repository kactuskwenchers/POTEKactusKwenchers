import SwiftUI
import FirebaseFirestore

struct KDSView: View {
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: KDSViewModel
    @State private var selectedStation: String? = nil
    @State private var availableStations: [String] = []
    @State private var displayedOrdersLimit = 20
    @State private var selectedStatusFilter: String? = nil

    init(category: String) {
        _viewModel = StateObject(wrappedValue: KDSViewModel(categoryFilter: category))
    }

    var filteredOrders: [Order] {
        if let filter = selectedStatusFilter {
            return viewModel.orders.filter { $0.status == filter }
        }
        return viewModel.orders
    }

    var body: some View {
        VStack(spacing: 0) {
            // Station and Status Filters with Back Button
            VStack(spacing: 8) {
                if !availableStations.isEmpty {
                    Picker("Select Station", selection: $selectedStation) {
                        Text("All Stations").tag(String?.none)
                        ForEach(availableStations, id: \.self) { station in
                            Text(station).tag(String?.some(station))
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                // Back Button and Status Filter Buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Back Button
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left.circle.fill")
                                    .font(.system(size: 24))
                                Text(LocalizedStringKey("Back"))
                                    .font(.system(size: 18, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color(hex: "#388E3C"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(hex: "#2E7D32"), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                        }

                        // Status Filter Buttons
                        Button(action: {
                            selectedStatusFilter = nil
                        }) {
                            Text(LocalizedStringKey("All Statuses"))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(selectedStatusFilter == nil ? .white : Color(hex: "#2E7D32"))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(selectedStatusFilter == nil ? Color(hex: "#388E3C") : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(hex: "#2E7D32"), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }

                        Button(action: {
                            selectedStatusFilter = "Pending"
                        }) {
                            Text(LocalizedStringKey("Pending"))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(selectedStatusFilter == "Pending" ? .white : Color(hex: "#2E7D32"))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(selectedStatusFilter == "Pending" ? Color(hex: "#388E3C") : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(hex: "#2E7D32"), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }

                        Button(action: {
                            selectedStatusFilter = "Held"
                        }) {
                            Text(LocalizedStringKey("Held"))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(selectedStatusFilter == "Held" ? .white : Color(hex: "#2E7D32"))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(selectedStatusFilter == "Held" ? Color(hex: "#388E3C") : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(hex: "#2E7D32"), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
                .background(Color.white)
            }

            // Header
            HStack {
                Text("\(viewModel.categoryFilter) KDS")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: "#2E7D32"))

                Spacer()

                if let user = authViewModel.user {
                    Text("\(user.email) - \(user.role.capitalized)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
            .background(Color.white)

            // Orders Grid
            ScrollView {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                        .padding()
                } else if filteredOrders.isEmpty {
                    Text("No orders to display")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 24),
                            GridItem(.flexible(), spacing: 24)
                        ],
                        spacing: 24
                    ) {
                        ForEach(filteredOrders.prefix(displayedOrdersLimit)) { order in
                            OrderCard(
                                order: order,
                                menuViewModel: menuViewModel,
                                onStatusChange: { newStatus in
                                    Task {
                                        do {
                                            try await viewModel.updateOrderStatus(orderId: order.id, newStatus: newStatus)
                                        } catch {
                                            viewModel.errorMessage = error.localizedDescription
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, max(16, UIScreen.main.bounds.width * 0.02))
                    .padding(.vertical, 24)

                    if filteredOrders.count > displayedOrdersLimit {
                        Button(action: {
                            displayedOrdersLimit += 20
                        }) {
                            Text("Load More Orders")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(Color(hex: "#2E7D32"))
                                .cornerRadius(12)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .background(Color(.systemGray6))
        .navigationBarHidden(true)
        .task {
            await fetchAvailableStations()
        }
    }

    private func fetchAvailableStations() async {
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("kdsSettings").document("stations").getDocument()
            if let data = snapshot.data(), let stations = data[viewModel.categoryFilter] as? [String] {
                availableStations = stations
                if selectedStation == nil, let firstStation = stations.first {
                    selectedStation = firstStation
                    viewModel.setStationId(firstStation)
                }
            }
        } catch {
            print("KDSView: Error fetching stations: \(error)")
        }
    }
}

struct KDSView_Previews: PreviewProvider {
    static var previews: some View {
        KDSView(category: "Drink")
            .environmentObject(MenuViewModel.shared)
            .environmentObject(AuthViewModel())
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
