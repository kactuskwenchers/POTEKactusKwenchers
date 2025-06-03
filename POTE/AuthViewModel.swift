import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var cashier: Employee? {
        didSet {
            print("AuthViewModel: Cashier updated to: \(cashier?.employeeId ?? "nil")")
        }
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("AuthViewModel: Initializing")
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            if let firebaseUser = firebaseUser, let email = firebaseUser.email {
                print("AuthViewModel: User state changed, email: \(email)")
                Task {
                    do {
                        self.isLoading = true
                        self.errorMessage = nil
                        let userDoc = try await FirebaseService.shared.fetchUserData(userId: firebaseUser.uid)
                        self.user = userDoc
                        print("AuthViewModel: Successfully fetched user data: \(userDoc)")
                    } catch {
                        print("AuthViewModel: Failed to fetch user data: \(error)")
                        self.errorMessage = error.localizedDescription
                        self.user = nil
                    }
                    self.isLoading = false
                }
            } else {
                print("AuthViewModel: No user signed in")
                self.user = nil
                self.isLoading = false
            }
        }
    }
    
    func login(email: String, password: String) async {
        do {
            self.isLoading = true
            self.errorMessage = nil
            let user = try await FirebaseService.shared.login(email: email, password: password)
            self.user = user
            print("AuthViewModel: Login successful for email: \(email)")
        } catch {
            self.errorMessage = error.localizedDescription
            print("AuthViewModel: Login failed: \(error)")
        }
        self.isLoading = false
    }
    
    func loginCashier(employeeId: String) async throws {
        do {
            self.isLoading = true
            self.errorMessage = nil
            let employee = try await FirebaseService.shared.validateEmployeeId(employeeId)
            self.cashier = employee
            print("AuthViewModel: Cashier login successful for employeeId: \(employeeId)")
        } catch {
            self.errorMessage = error.localizedDescription
            print("AuthViewModel: Cashier login failed: \(error)")
            throw error
        }
        self.isLoading = false
    }
    
    func logout() async {
        do {
            self.isLoading = true
            self.errorMessage = nil
            try Auth.auth().signOut()
            self.user = nil
            self.cashier = nil
            print("AuthViewModel: Logout successful")
        } catch {
            self.errorMessage = error.localizedDescription
            print("AuthViewModel: Logout failed: \(error)")
        }
        self.isLoading = false
    }
    
    func logoutCashier() {
        self.cashier = nil
        print("AuthViewModel: Cashier logout successful")
    }
}
