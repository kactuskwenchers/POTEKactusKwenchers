import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import Combine

// Struct to model tax rate data
struct TaxRate: Identifiable, Codable {
    let id: String // Document ID (e.g., "Mesa")
    let city: String
    let totalRate: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case city
        case totalRate = "totalrate"
    }
}

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func login(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let firebaseUser = result.user
        return try await fetchUserData(userId: firebaseUser.uid)
    }
    
    func fetchUserData(userId: String) async throws -> User {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data(),
              let email = userData["email"] as? String,
              let role = userData["role"] as? String else {
            throw NSError(domain: "Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])
        }
        return User(id: userId, email: email, role: role)
    }
    
    func validateEmployeeId(_ employeeId: String) async throws -> Employee {
        print("FirebaseService: Querying employees collection for employeeId: \(employeeId)")
        let snapshot = try await db.collection("employees")
            .whereField("employeeId", isEqualTo: employeeId)
            .getDocuments()
        
        print("FirebaseService: Query returned \(snapshot.documents.count) documents")
        guard let document = snapshot.documents.first,
              let employee = try? document.data(as: Employee.self) else {
            throw NSError(domain: "Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Employee not found"])
        }
        
        return employee
    }
    
    func saveOrder(_ order: Order) async throws {
        print("FirebaseService: Saving order with total: \(order.total), cashierId: \(order.cashierId)")
        try await db.collection("orders").document(order.id).setData([
            "id": order.id,
            "items": order.items.map { ["itemId": $0.itemId, "quantity": $0.quantity] },
            "total": order.total,
            "status": order.status,
            "timestamp": Timestamp(date: order.timestamp),
            "cashierId": order.cashierId,
            "orderNumber": order.orderNumber as Any,
            "paymentId": order.paymentId as Any,
            "paymentType": order.paymentType as Any
        ])
        print("FirebaseService: Order saved successfully")
    }
    
    func fetchItems() async throws -> [MenuItem] {
        let snapshot = try await db.collection("menu_items").getDocuments()
        var items: [MenuItem] = []
        for document in snapshot.documents {
            do {
                let item = try document.data(as: MenuItem.self)
                items.append(item)
            } catch {
                print("FirebaseService: Failed to decode MenuItem from document \(document.documentID): \(error)")
            }
        }
        return items
    }
    
    func fetchOrders() async throws -> [Order] {
        let snapshot = try await db.collection("orders")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: Order.self)
        }
    }
    
    func searchOrders(orderNumber: Int, cashierId: String) async throws -> [Order] {
        let snapshot = try await db.collection("orders")
            .whereField("orderNumber", isEqualTo: orderNumber)
            .whereField("cashierId", isEqualTo: cashierId)
            .getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: Order.self)
        }
    }
    
    func updateOrderStatus(orderId: String, status: String) async throws {
        try await db.collection("orders").document(orderId).updateData([
            "status": status,
            "timestamp": Timestamp(date: Date())
        ])
    }
    
    func fetchTaxRates() async throws -> [TaxRate] {
        let snapshot = try await db.collection("sales_tax_rates").getDocuments()
        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let city = data["city"] as? String,
                  let totalRateString = data["totalrate"] as? String,
                  let totalRate = Double(totalRateString) else {
                print("FirebaseService: Failed to parse tax rate for document \(document.documentID)")
                return nil
            }
            return TaxRate(id: document.documentID, city: city, totalRate: totalRate)
        }
    }
}
