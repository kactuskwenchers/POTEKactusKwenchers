import SwiftUI
import FirebaseFirestore

struct ToastKDSView: View {
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        KDSView(category: "Toast")
            .environmentObject(menuViewModel)
            .environmentObject(authViewModel)
    }
}

struct ToastKDSView_Previews: PreviewProvider {
    static var previews: some View {
        ToastKDSView()
            .environmentObject(MenuViewModel.shared)
            .environmentObject(AuthViewModel())
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
