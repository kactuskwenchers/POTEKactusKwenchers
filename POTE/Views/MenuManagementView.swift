//
//  MenuManagementView.swift
//  POTE
//
//  Created by Kacrtus Kwenchers on 5/31/25.
//

import SwiftUI

 struct MenuManagementView: View {
     var body: some View {
         ZStack {
             Color(.systemGray6)
                 .ignoresSafeArea()
             VStack {
                 Text("Menu Management")
                     .font(.system(size: 32, weight: .bold))
                     .foregroundColor(.primary)
                 Text("Placeholder for menu management functionality")
                     .font(.system(size: 18))
                     .foregroundColor(.secondary)
             }
         }
         .navigationBarHidden(true)
     }
 }

 struct MenuManagementView_Previews: PreviewProvider {
     static var previews: some View {
         MenuManagementView()
             .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
     }
 }
