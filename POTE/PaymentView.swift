import SwiftUI
import SquareMobilePaymentsSDK

struct PaymentView: View {
    let amount: Int // Amount in cents
    let orderViewModel: OrderViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var paymentResult: Payment?
    @State private var showSquarePayment = false
    @State private var showCashPayment = false
    @State private var cashTendered = ""
    @State private var changeDue: Double?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 30) {
                // Header: Payment Title
                Text("Payment")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(Color(hex: "#2E7D32"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)

                // Total Amount
                Text("Total: $\(String(format: "%.2f", Double(amount) / 100))")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)

                // Payment Result or Change Due
                if let paymentResult = paymentResult {
                    Text("Payment Successful! ID: \(paymentResult.id)")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)

                    Button(action: {
                        orderViewModel.resetOrder()
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 40)
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .background(Color(hex: "#2E7D32"))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)
                } else if let changeDue = changeDue {
                    Text("Change Due: $\(String(format: "%.2f", changeDue))")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)

                    Button(action: {
                        orderViewModel.resetOrder()
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 40)
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .background(Color(hex: "#2E7D32"))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)
                } else {
                    // Payment Buttons
                    Button(action: {
                        showSquarePayment = true
                    }) {
                        Text("Pay by Card")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 40)
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .background(Color(hex: "#2E7D32"))
                            .cornerRadius(16)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 40)

                    Button(action: {
                        showCashPayment = true
                    }) {
                        Text("Pay by Cash")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 40)
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .background(Color(hex: "#0288D1"))
                            .cornerRadius(16)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 40)

                    // Loading Indicator
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color(hex: "#2E7D32"))
                            .scaleEffect(1.5)
                            .padding(.vertical, 20)
                    }

                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 20)
            .background(Color(.systemGray6))
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showSquarePayment) {
            SquarePaymentView(
                amount: amount,
                onCompletion: { result in
                    showSquarePayment = false
                    isLoading = false
                    switch result {
                    case .success(let payment):
                        paymentResult = payment
                        Task {
                            do {
                                let cashierId = authViewModel.cashier?.employeeId ?? "unknown"
                                print("PaymentView: Saving order with cashierId: \(cashierId) for Card payment")
                                try await orderViewModel.saveOrder(
                                    cashierId: cashierId,
                                    paymentType: "Card",
                                    paymentId: payment.id
                                )
                            } catch {
                                errorMessage = error.localizedDescription
                                print("PaymentView: Save order error: \(error)")
                            }
                        }
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        print("PaymentView: Payment error: \(error)")
                    }
                }
            )
        }
        .sheet(isPresented: $showCashPayment) {
            CashPaymentView(
                total: Double(amount) / 100,
                onConfirm: { tendered in
                    let change = tendered - (Double(amount) / 100)
                    if change >= 0 {
                        changeDue = change
                        Task {
                            do {
                                let cashierId = authViewModel.cashier?.employeeId ?? "unknown"
                                print("PaymentView: Saving order with cashierId: \(cashierId) for Cash payment")
                                try await orderViewModel.saveOrder(
                                    cashierId: cashierId,
                                    paymentType: "Cash",
                                    paymentId: nil as String?
                                )
                            } catch {
                                errorMessage = error.localizedDescription
                                print("PaymentView: Save order error: \(error)")
                            }
                        }
                    } else {
                        errorMessage = "Insufficient cash tendered"
                    }
                    showCashPayment = false
                    isLoading = false
                },
                onCancel: {
                    showCashPayment = false
                    isLoading = false
                }
            )
            .presentationDetents([.medium])
        }
        .onChange(of: showSquarePayment) { isPresented in
            if isPresented {
                isLoading = true
            }
        }
        .onChange(of: showCashPayment) { isPresented in
            if isPresented {
                isLoading = true
            }
        }
    }
}

struct CashPaymentView: View {
    let total: Double
    let onConfirm: (Double) -> Void
    let onCancel: () -> Void
    @State private var cashTendered = ""
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 30) {
                Text("Cash Payment")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                
                Text("Total: $\(String(format: "%.2f", total))")
                    .font(.system(size: 28))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
                
                TextField("Amount Tendered", text: $cashTendered)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24))
                    .padding(.horizontal, 40)
                    .frame(height: 60)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                
                HStack(spacing: 24) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 30)
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(Color(hex: "#FF6200"))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        if let tendered = Double(cashTendered) {
                            onConfirm(tendered)
                        } else {
                            onConfirm(0)
                        }
                    }) {
                        Text("Confirm")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 30)
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(Color(hex: "#2E7D32"))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
        }
    }
}

struct SquarePaymentView: UIViewControllerRepresentable {
    let amount: Int
    let onCompletion: (Result<Payment, Error>) -> Void

    func makeUIViewController(context: Context) -> SquarePaymentViewController {
        let controller = SquarePaymentViewController(amount: amount, onCompletion: onCompletion)
        return controller
    }

    func updateUIViewController(_ uiViewController: SquarePaymentViewController, context: Context) {
        // No updates needed for now
    }
}

class SquarePaymentViewController: UIViewController {
    let amount: Int
    let onCompletion: (Result<Payment, Error>) -> Void

    init(amount: Int, onCompletion: @escaping (Result<Payment, Error>) -> Void) {
        self.amount = amount
        self.onCompletion = onCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startPayment()
    }

    private func startPayment() {
        SquareService.shared.startPayment(
            amount: amount,
            viewController: self,
            completion: { [weak self] result in
                self?.onCompletion(result)
            }
        )
    }
}

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView(amount: 1498, orderViewModel: OrderViewModel())
            .environmentObject(MenuViewModel.shared)
            .environmentObject(AuthViewModel())
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
