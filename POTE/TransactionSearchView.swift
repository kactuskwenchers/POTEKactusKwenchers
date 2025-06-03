import SwiftUI

struct TransactionSearchView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var orders: [Order] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRefundConfirmation = false
    @State private var selectedOrder: Order?
    @State private var refundError: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Error Message for Refund
                if let refundError = refundError {
                    Text(refundError)
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Results
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color(hex: "#2E7D32"))
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if orders.isEmpty {
                    Text("No transactions found")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(orders) { order in
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Order #\(order.orderNumber ?? 0)")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Total: $\(String(format: "%.2f", order.total))")
                                    .font(.system(size: 16))
                                Text("Status: \(order.status)")
                                    .font(.system(size: 16))
                                Text("Date: \(order.timestamp, formatter: dateFormatter)")
                                    .font(.system(size: 16))
                            }
                            Spacer()
                            if order.status == "Completed" && authViewModel.user?.role == "manager" && order.paymentType == "Card" {
                                Button(action: {
                                    selectedOrder = order
                                    showRefundConfirmation = true
                                }) {
                                    Text("Refund")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color(hex: "#D32F2F"))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Confirm Refund", isPresented: $showRefundConfirmation) {
                Button("Cancel", role: .cancel) {
                    selectedOrder = nil
                }
                Button("Refund", role: .destructive) {
                    if let order = selectedOrder {
                        processRefund(for: order)
                    }
                }
            } message: {
                Text("Refund Order #\(selectedOrder?.orderNumber ?? 0) for $\(String(format: "%.2f", selectedOrder?.total ?? 0))?")
            }
            .onAppear {
                fetchOrders()
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func fetchOrders() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let fetchedOrders = try await FirebaseService.shared.fetchOrders()
                orders = fetchedOrders
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func processRefund(for order: Order) {
        isLoading = true
        refundError = nil
        Task {
            do {
                if let paymentId = order.paymentId {
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                        SquareService.shared.refundPayment(paymentId: paymentId, amount: Int(order.total * 100)) { result in
                            switch result {
                            case .success:
                                continuation.resume(returning: ())
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                    try await FirebaseService.shared.updateOrderStatus(orderId: order.id, status: "Refunded")
                    orders = try await FirebaseService.shared.fetchOrders()
                } else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No payment ID found for refund"])
                }
            } catch {
                refundError = error.localizedDescription
            }
            isLoading = false
            selectedOrder = nil
        }
    }
}

struct TransactionSearchView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionSearchView()
            .environmentObject(AuthViewModel())
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
