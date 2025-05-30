//
//  ToastKDSView.swift
//  POTE
//
//  Created by Kacrtus Kwenchers on 5/31/25.
//

import SwiftUI
import FirebaseFirestore
struct ToastKDSView: View {
    @EnvironmentObject var menuViewModel: MenuViewModel

    var body: some View {
        KDSView(category: "Toast")
            .environmentObject(menuViewModel)
    }
}

struct ToastKDSView_Previews: PreviewProvider {
    static var previews: some View {
        ToastKDSView()
            .environmentObject(MenuViewModel.shared)
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
