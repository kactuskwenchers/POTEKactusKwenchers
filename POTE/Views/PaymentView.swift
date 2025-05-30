import SwiftUI
import SquareMobilePaymentsSDK
import CoreLocation

struct PaymentView: View {
    let amount: Int // Amount in cents
    let orderViewModel: OrderViewModel
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var paymentResult: Payment?
    @State private var showSquarePayment = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Payment")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#2E7D32"))

            Text("Total: $\(String(format: "%.2f", Double(amount) / 100))")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)

            if let paymentResult = paymentResult {
                Text("Payment Successful! ID: \(paymentResult.id)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)

                Button(action: {
                    orderViewModel.resetOrder()
                    dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(hex: "#2E7D32"))
                        .cornerRadius(12)
                }
            } else {
                Button(action: {
                    showSquarePayment = true
                }) {
                    Text("Pay Now")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(hex: "#2E7D32"))
                        .cornerRadius(12)
                }
                .disabled(isLoading)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color(hex: "#2E7D32"))
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .sheet(isPresented: $showSquarePayment) {
            SquarePaymentView(
                amount: amount,
                onCompletion: { result in
                    showSquarePayment = false
                    isLoading = false
                    switch result {
                    case .success(let payment):
                        paymentResult = payment
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        print("Payment error: \(error)")
                    }
                }
            )
        }
        .onChange(of: showSquarePayment) { isPresented in
            if isPresented {
                isLoading = true
            }
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
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
