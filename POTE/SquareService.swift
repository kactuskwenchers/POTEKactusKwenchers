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
    
    func refundPayment(paymentId: String, amount: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !isPaymentInProgress else {
            let error = NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "A payment operation is in progress"])
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        
        let accessToken = Bundle.main.object(forInfoDictionaryKey: "SQUARE_ACCESS_TOKEN") as? String ?? ""
        guard !accessToken.isEmpty else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Square access token"])
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        
        isPaymentInProgress = true
        let url = URL(string: "https://connect.squareup.com/v2/refunds")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "idempotency_key": UUID().uuidString,
            "payment_id": paymentId,
            "amount_money": [
                "amount": amount,
                "currency": "USD"
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            isPaymentInProgress = false
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isPaymentInProgress = false
                if let error = error {
                    print("Refund error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Refund request failed"])
                    print("Refund error: Invalid response")
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
            }
        }.resume()
    }
    
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
