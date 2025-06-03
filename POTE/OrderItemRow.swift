//
//  OrderItemRow.swift
//  POTE
//
//  Created by Kacrtus Kwenchers on 6/2/25.
//


import SwiftUI

struct OrderItemRow: View {
    let orderItem: OrderItem
    let itemName: String
    let isTapped: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text("\(itemName) x\(orderItem.quantity)")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.primary)
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#FF6200"))
                    .scaleEffect(isTapped ? 0.9 : 1.0)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
