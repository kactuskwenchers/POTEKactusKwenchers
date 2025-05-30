//
//  DrinkKDSView.swift
//  POTE
//
//  Created by Kacrtus Kwenchers on 5/31/25.
//
import SwiftUI
import FirebaseFirestore
struct DrinkKDSView: View {
    @EnvironmentObject var menuViewModel: MenuViewModel

    var body: some View {
        KDSView(category: "Drink")
            .environmentObject(menuViewModel)
    }
}

struct DrinkKDSView_Previews: PreviewProvider {
    static var previews: some View {
        DrinkKDSView()
            .environmentObject(MenuViewModel.shared)
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
