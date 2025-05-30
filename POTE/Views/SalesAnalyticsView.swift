//
//  SalesAnalyticsView.swift
//  POTE
//
//  Created by Kacrtus Kwenchers on 5/31/25.
//
import SwiftUI

 struct SalesAnalyticsView: View {
     var body: some View {
         ZStack {
             Color(.systemGray6)
                 .ignoresSafeArea()
             VStack {
                 Text("Sales Analytics")
                     .font(.system(size: 32, weight: .bold))
                     .foregroundColor(.primary)
                 Text("Placeholder for sales analytics functionality")
                     .font(.system(size: 18))
                     .foregroundColor(.secondary)
             }
         }
         .navigationBarHidden(true)
     }
 }

 struct SalesAnalyticsView_Previews: PreviewProvider {
     static var previews: some View {
         SalesAnalyticsView()
             .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
     }
 }
