import SwiftUI

struct LandingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var menuViewModel: MenuViewModel
    @State private var selectedModule: String?
    @State private var isTappedCard: String?
    @State private var isLogoVisible = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()

                GeometryReader { geometry in
                    VStack(spacing: 32) {
                        // Header with POTE branding
                        HStack {
                            Image("POTEIconSmall")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                                .foregroundColor(Color(hex: "#00FF00"))
                            Text("POTE")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "#2E7D32"))
                            Spacer()
                        }
                        .padding(.top, 24)
                        .padding(.horizontal, 32)
                        .opacity(isLogoVisible ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3), value: isLogoVisible)
                        .onAppear { isLogoVisible = true }

                        ScrollView {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 24),
                                    GridItem(.flexible(), spacing: 24),
                                    GridItem(.flexible(), spacing: 24)
                                ],
                                spacing: 24
                            ) {
                                // Drink KDS
                                NavigationCard(
                                    title: "Drink KDS",
                                    icon: "cup.and.saucer.fill",
                                    isTapped: isTappedCard == "DrinkKDS"
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        isTappedCard = "DrinkKDS"
                                    }
                                    selectedModule = "DrinkKDS"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isTappedCard = nil
                                    }
                                }

                                // Toast KDS
                                NavigationCard(
                                    title: "Toast KDS",
                                    icon: "fork.knife",
                                    isTapped: isTappedCard == "ToastKDS"
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        isTappedCard = "ToastKDS"
                                    }
                                    selectedModule = "ToastKDS"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isTappedCard = nil
                                    }
                                }

                                // Inventory
                                NavigationCard(
                                    title: "Inventory",
                                    icon: "archivebox.fill",
                                    isTapped: isTappedCard == "Inventory"
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        isTappedCard = "Inventory"
                                    }
                                    selectedModule = "Inventory"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isTappedCard = nil
                                    }
                                }

                                // HR
                                NavigationCard(
                                    title: "HR",
                                    icon: "person.2.fill",
                                    isTapped: isTappedCard == "HR"
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        isTappedCard = "HR"
                                    }
                                    selectedModule = "HR"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isTappedCard = nil
                                    }
                                }

                                // Time Card
                                NavigationCard(
                                    title: "Time Card",
                                    icon: "clock.fill",
                                    isTapped: isTappedCard == "TimeCard"
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        isTappedCard = "TimeCard"
                                    }
                                    selectedModule = "TimeCard"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isTappedCard = nil
                                    }
                                }

                                // Sales Analytics
                                NavigationCard(
                                    title: "Sales Analytics",
                                    icon: "chart.bar.fill",
                                    isTapped: isTappedCard == "SalesAnalytics"
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        isTappedCard = "SalesAnalytics"
                                    }
                                    selectedModule = "SalesAnalytics"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isTappedCard = nil
                                    }
                                }

                                // Customer Display
                                NavigationCard(
                                    title: "Customer Display",
                                    icon: "tv.fill",
                                    isTapped: isTappedCard == "CustomerDisplay"
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        isTappedCard = "CustomerDisplay"
                                    }
                                    selectedModule = "CustomerDisplay"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isTappedCard = nil
                                    }
                                }

                                // Menu Management
                                NavigationCard(
                                    title: "Menu Management",
                                    icon: "list.bullet.rectangle.fill",
                                    isTapped: isTappedCard == "MenuManagement"
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        isTappedCard = "MenuManagement"
                                    }
                                    selectedModule = "MenuManagement"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isTappedCard = nil
                                    }
                                }
                            }
                            .padding(.horizontal, max(32, geometry.size.width * 0.05))
                            .padding(.vertical, 24)
                        }
                    }
                }

                // Programmatic navigation for modules
                NavigationLink(
                    destination: destinationView(),
                    isActive: Binding(
                        get: { selectedModule != nil },
                        set: { if !$0 { selectedModule = nil } }
                    ),
                    label: { EmptyView() }
                )
            }
            .navigationBarHidden(true)
            .task {
                await menuViewModel.fetchItems()
            }
            .onChange(of: selectedModule) { newValue in
                print("LandingView: selectedModule changed to \(String(describing: newValue))")
            }
        }
    }

    // Returns the destination view based on selectedModule
    @ViewBuilder
    private func destinationView() -> some View {
        switch selectedModule {
        case "DrinkKDS":
            DrinkKDSView()
                .environmentObject(menuViewModel)
        case "ToastKDS":
            ToastKDSView()
                .environmentObject(menuViewModel)
        case "Inventory":
            InventoryView()
        case "HR":
            HRView()
        case "TimeCard":
            TimeCardView()
        case "SalesAnalytics":
            SalesAnalyticsView()
        case "CustomerDisplay":
            CustomerDisplayView()
        case "MenuManagement":
            MenuManagementView()
        default:
            EmptyView()
        }
    }
}

struct NavigationCard: View {
    let title: String
    let icon: String
    let isTapped: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#2E7D32"))
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(minWidth: 200, minHeight: 200)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .scaleEffect(isTapped ? 0.95 : 1.0)
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
            .environmentObject(MenuViewModel.shared)
            .environmentObject(AuthViewModel())
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
