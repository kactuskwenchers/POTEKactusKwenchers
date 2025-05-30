import Foundation
import Combine
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            print("Starting login process at \(Date())")
            print("Attempting Firebase login with email: \(email)")
            let user = try await FirebaseService.shared.login(email: email, password: password)
            self.user = user
            print("Firebase login succeeded, user: \(email)")
            
            print("Attempting Square authorization")
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                SquareService.shared.authorize { result in
                    switch result {
                    case .success:
                        print("Login and Square authorization completed successfully")
                        continuation.resume(returning: ())
                    case .failure(let error):
                        print("Square authorization error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Login error: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func logout() async {
        do {
            try Auth.auth().signOut()
            user = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            print("Logout error: \(error.localizedDescription)")
        }
    }
}
