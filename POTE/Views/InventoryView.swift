//
//  KDSView.swift
//  POTE
//
//  Created by Kacrtus Kwenchers on 5/31/25.
//
import SwiftUI

 struct InventoryView: View {
     var body: some View {
         ZStack {
             Color(.systemGray6)
                 .ignoresSafeArea()
             VStack {
                 Text("Inventory")
                     .font(.system(size: 32, weight: .bold))
                     .foregroundColor(.primary)
                 Text("Placeholder for Inventory functionality")
                     .font(.system(size: 18))
                     .foregroundColor(.secondary)
             }
         }
         .navigationBarHidden(true)
     }
 }

 struct InventoryView_Previews: PreviewProvider {
     static var previews: some View {
         InventoryView()
             .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
     }
 }
