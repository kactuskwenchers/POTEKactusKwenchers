import SwiftUI

struct CashierLoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showLogin: Bool
    @Binding var navigateToPOS: Bool
    @State private var employeeIdInput = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 15) {
                // Title
                Text("Cashier Login")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: "#2E7D32"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                
                // Display Entered Employee ID
                Text(employeeIdInput.isEmpty ? "0000" : employeeIdInput)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: min(geometry.size.width * 0.6, 300), height: 80)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 40)
                
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Loading Indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color(hex: "#2E7D32"))
                        .scaleEffect(1.5)
                }
                
                // Numerical Keypad
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ], spacing: 2) {
                    ForEach(1..<10) { number in
                        Button(action: {
                            if employeeIdInput.count < 4 {
                                employeeIdInput += String(number)
                            }
                        }) {
                            Text("\(number)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 90, height: 90)
                                .background(Color.gray)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                        }
                    }
                    Button(action: {
                        employeeIdInput = ""
                    }) {
                        Text("Clear")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 90, height: 90)
                            .background(Color(hex: "#FF6200"))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                    }
                    Button(action: {
                        if employeeIdInput.count < 4 {
                            employeeIdInput += "0"
                        }
                    }) {
                        Text("0")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 90, height: 90)
                            .background(Color.gray)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, max(20, geometry.size.width * 0.05))
                
                // Action Buttons
                HStack(spacing: 10) {
                    Button(action: {
                        showLogin = false
                    }) {
                        Text("Cancel")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(Color(hex: "#FF6200"))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    Button(action: {
                        Task {
                            await loginCashier()
                        }
                    }) {
                        Text("Login")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(Color(hex: "#2E7D32"))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .disabled(isLoading || employeeIdInput.count != 4)
                }
                .padding(.horizontal, max(20, geometry.size.width * 0.05))
                .padding(.vertical, 10)
                
                Spacer()
            }
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
    }
    
    private func loginCashier() async {
        guard employeeIdInput.count == 4 else {
            errorMessage = "Please enter a 4-digit employee ID"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("CashierLoginView: Attempting to log in with employeeId: \(employeeIdInput)")
            try await authViewModel.loginCashier(employeeId: employeeIdInput)
            print("CashierLoginView: Login successful for employeeId: \(employeeIdInput)")
            showLogin = false
        } catch {
            if error.localizedDescription.contains("Missing or insufficient permissions") {
                errorMessage = "Permission denied. Please contact an administrator."
            } else {
                errorMessage = "Invalid employee ID. Please try again."
            }
            print("CashierLoginView: Login failed with error: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}

struct CashierLoginView_Previews: PreviewProvider {
    @State static var showLogin = true
    @State static var navigateToPOS = false
    
    static var previews: some View {
        CashierLoginView(showLogin: $showLogin, navigateToPOS: $navigateToPOS)
            .environmentObject(AuthViewModel())
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
