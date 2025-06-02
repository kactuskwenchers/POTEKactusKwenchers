import SquareMobilePaymentsSDK
import Foundation
import UIKit

class SquareService: NSObject, PaymentManagerDelegate {
    static let shared = SquareService()
    private var paymentHandle: PaymentHandle?
    private var paymentCompletion: ((Result<Payment, Error>) -> Void)?
    private var isPaymentInProgress: Bool = false
    
    private override init() {
        super.init()
    }
    
    func authorize(completion: @escaping (Result<Void, Error>) -> Void) {
        guard MobilePaymentsSDK.shared.authorizationManager.state == .notAuthorized else {
            print("Square SDK already authorized.")
            DispatchQueue.main.async {
                completion(.success(()))
            }
            return
        }
        
        let accessToken = Bundle.main.object(forInfoDictionaryKey: "SQUARE_ACCESS_TOKEN") as? String ?? ""
        let locationId = Bundle.main.object(forInfoDictionaryKey: "SQUARE_LOCATION_ID") as? String ?? ""
        
        guard !accessToken.isEmpty, !locationId.isEmpty else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Square access token or location ID"])
            print("Square authorization failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        
        print("Authorizing Square with locationId: \(locationId)")
        MobilePaymentsSDK.shared.authorizationManager.authorize(
            withAccessToken: accessToken,
            locationID: locationId
        ) { error in
            DispatchQueue.main.async {
                if let error {
                    print("Square authorization failed: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Square authorization succeeded.")
                    completion(.success(()))
                }
            }
        }
    }
    
    func deauthorize(completion: @escaping () -> Void) {
        MobilePaymentsSDK.shared.authorizationManager.deauthorize {
            print("Square SDK deauthorized.")
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func startPayment(amount: Int, viewController: UIViewController, completion: @escaping (Result<Payment, Error>) -> Void) {
        // Prevent concurrent payments
        guard !isPaymentInProgress else {
            let error = NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "A payment is already in progress"])
            print("Payment error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        
        guard amount > 0 else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Amount must be positive"])
            print("Payment error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        
        // Ensure authorization before starting payment
        authorize { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Starting payment for amount: \(amount) cents")
                    self.isPaymentInProgress = true
                    let parameters = PaymentParameters(
                        idempotencyKey: UUID().uuidString,
                        amountMoney: Money(amount: UInt(amount), currency: .USD),
                        processingMode: .onlineOnly
                    )
                    
                    self.paymentCompletion = completion
                    self.paymentHandle = MobilePaymentsSDK.shared.paymentManager.startPayment(
                        parameters,
                        promptParameters: PromptParameters(mode: .default, additionalMethods: .all),
                        from: viewController,
                        delegate: self
                    )
                case .failure(let error):
                    print("Payment error: Failed to authorize Square: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    // PaymentManagerDelegate methods
    func paymentManager(_ paymentManager: PaymentManager, didFinish payment: Payment) {
        print("Payment succeeded: \(payment.id)")
        DispatchQueue.main.async {
            self.paymentCompletion?(.success(payment))
            self.paymentCompletion = nil
            self.paymentHandle = nil
            self.isPaymentInProgress = false
        }
    }
    
    func paymentManager(_ paymentManager: PaymentManager, didFail payment: Payment, withError error: Error) {
        print("Payment failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.paymentCompletion?(.failure(error))
            self.paymentCompletion = nil
            self.paymentHandle = nil
            self.isPaymentInProgress = false
        }
    }
    
    func paymentManager(_ paymentManager: PaymentManager, didCancel payment: Payment) {
        print("Payment cancelled")
        let error = NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Payment was cancelled"])
        DispatchQueue.main.async {
            self.paymentCompletion?(.failure(error))
            self.paymentCompletion = nil
            self.paymentHandle = nil
            self.isPaymentInProgress = false
        }
    }
}
