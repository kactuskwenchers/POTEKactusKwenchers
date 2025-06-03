import Foundation
import FirebaseFirestore

struct Order: Codable, Equatable, Identifiable {
    let id: String
    let items: [OrderItem]
    let total: Double
    let status: String
    let timestamp: Date
    let cashierId: String
    let orderNumber: Int?
    let paymentId: String?
    let paymentType: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case items
        case total
        case status
        case timestamp
        case cashierId
        case orderNumber
        case paymentId
        case paymentType
    }
    
    static func ==(lhs: Order, rhs: Order) -> Bool {
        return lhs.id == rhs.id &&
               lhs.items == rhs.items &&
               lhs.total == rhs.total &&
               lhs.status == rhs.status &&
               lhs.timestamp == rhs.timestamp &&
               lhs.cashierId == rhs.cashierId &&
               lhs.orderNumber == rhs.orderNumber &&
               lhs.paymentId == rhs.paymentId &&
               lhs.paymentType == rhs.paymentType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        items = try container.decode([OrderItem].self, forKey: .items)
        total = try container.decode(Double.self, forKey: .total)
        status = try container.decode(String.self, forKey: .status)
        let timestampValue = try container.decode(Timestamp.self, forKey: .timestamp)
        timestamp = timestampValue.dateValue()
        cashierId = try container.decode(String.self, forKey: .cashierId)
        orderNumber = try container.decodeIfPresent(Int.self, forKey: .orderNumber)
        paymentId = try container.decodeIfPresent(String.self, forKey: .paymentId)
        paymentType = try container.decodeIfPresent(String.self, forKey: .paymentType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(items, forKey: .items)
        try container.encode(total, forKey: .total)
        try container.encode(status, forKey: .status)
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
        try container.encode(cashierId, forKey: .cashierId)
        try container.encodeIfPresent(orderNumber, forKey: .orderNumber)
        try container.encodeIfPresent(paymentId, forKey: .paymentId)
        try container.encodeIfPresent(paymentType, forKey: .paymentType)
    }
    
    init(id: String = UUID().uuidString, items: [OrderItem], total: Double, status: String, timestamp: Date, cashierId: String, orderNumber: Int? = nil, paymentId: String? = nil, paymentType: String? = nil) {
        self.id = id
        self.items = items
        self.total = total
        self.status = status
        self.timestamp = timestamp
        self.cashierId = cashierId
        self.orderNumber = orderNumber
        self.paymentId = paymentId
        self.paymentType = paymentType
    }
}
