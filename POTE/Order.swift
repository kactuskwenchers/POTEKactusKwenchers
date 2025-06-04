import Foundation
import FirebaseFirestore

struct Order: Codable, Equatable, Identifiable {
    let id: String
    let items: [OrderItem]
    let total: Double
    let status: String
    let timestamp: Date
    let cashierId: String
    let stationId: String?
    let priority: String?

    enum CodingKeys: String, CodingKey {
        case id
        case items
        case total
        case status
        case timestamp
        case cashierId
        case stationId
        case priority
    }

    static func ==(lhs: Order, rhs: Order) -> Bool {
        return lhs.id == rhs.id &&
               lhs.items == rhs.items &&
               lhs.total == rhs.total &&
               lhs.status == rhs.status &&
               lhs.timestamp == rhs.timestamp &&
               lhs.cashierId == rhs.cashierId &&
               lhs.stationId == rhs.stationId &&
               lhs.priority == rhs.priority
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
        stationId = try container.decodeIfPresent(String.self, forKey: .stationId)
        priority = try container.decodeIfPresent(String.self, forKey: .priority)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(items, forKey: .items)
        try container.encode(total, forKey: .total)
        try container.encode(status, forKey: .status)
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
        try container.encode(cashierId, forKey: .cashierId)
        try container.encodeIfPresent(stationId, forKey: .stationId)
        try container.encodeIfPresent(priority, forKey: .priority)
    }

    init(id: String = UUID().uuidString, items: [OrderItem], total: Double, status: String, timestamp: Date, cashierId: String, stationId: String? = nil, priority: String? = nil) {
        self.id = id
        self.items = items
        self.total = total
        self.status = status
        self.timestamp = timestamp
        self.cashierId = cashierId
        self.stationId = stationId
        self.priority = priority
    }
}
