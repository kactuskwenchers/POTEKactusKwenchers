import SwiftUI
import FirebaseFirestore

struct DrinkKDSView: View {
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        KDSView(category: "Drink")
            .environmentObject(menuViewModel)
            .environmentObject(authViewModel)
    }
}

struct DrinkKDSView_Previews: PreviewProvider {
    static var previews: some View {
        DrinkKDSView()
            .environmentObject(MenuViewModel.shared)
            .environmentObject(AuthViewModel())
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
