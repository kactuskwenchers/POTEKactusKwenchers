import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var menuViewModel: MenuViewModel
    @State private var email = "test@kactuskwenchers.com"
    @State private var password = "Test1234"
    @State private var isLogoVisible = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // POTE Branding
                    Image("POTEIconLarge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .foregroundColor(Color(hex: "#00FF00"))
                        .opacity(isLogoVisible ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5), value: isLogoVisible)
                        .onAppear { isLogoVisible = true }
                    
                    Text("POTE")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(hex: "#2E7D32"))
                        .opacity(isLogoVisible ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(0.2), value: isLogoVisible)
                    
                    // Email Field
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding(.horizontal, 32)
                        .frame(height: 48)
                    
                    // Password Field
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 32)
                        .frame(height: 48)
                    
                    // Login Button
                    Button(action: {
                        Task {
                            await authViewModel.login(email: email, password: password)
                        }
                    }) {
                        Text("Login")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#2E7D32"), Color(hex: "#388E3C")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .padding(.horizontal, 32)
                            .frame(height: 56)
                    }
                    .disabled(authViewModel.isLoading)
                    
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .padding(.horizontal, 32)
                            .multilineTextAlignment(.center)
                    }
                    
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color(hex: "#2E7D32"))
                    }
                }
                
                // Navigation to LandingView
                NavigationLink(
                    destination: LandingView()
                        .environmentObject(menuViewModel)
                        .environmentObject(authViewModel),
                    isActive: Binding(
                        get: { authViewModel.user != nil },
                        set: { _ in }
                    ),
                    label: { EmptyView() }
                )
            }
            .navigationBarHidden(true)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
            .environmentObject(MenuViewModel.shared)
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
