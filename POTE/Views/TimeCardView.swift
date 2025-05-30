//
//  TimeCardView.swift
//  POTE
//
//  Created by Kacrtus Kwenchers on 5/31/25.
//

import SwiftUI

 struct TimeCardView: View {
     var body: some View {
         ZStack {
             Color(.systemGray6)
                 .ignoresSafeArea()
             VStack {
                 Text("Time Card")
                     .font(.system(size: 32, weight: .bold))
                     .foregroundColor(.primary)
                 Text("Placeholder for time card functionality")
                     .font(.system(size: 18))
                     .foregroundColor(.secondary)
             }
         }
         .navigationBarHidden(true)
     }
 }

 struct TimeCardView_Previews: PreviewProvider {
     static var previews: some View {
         TimeCardView()
             .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
     }
 }
