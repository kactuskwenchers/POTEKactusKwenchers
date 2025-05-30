import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func login(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let firebaseUser = result.user
        
        let userDoc = try await db.collection("users").document(firebaseUser.uid).getDocument()
        guard let userData = userDoc.data(),
              let email = userData["email"] as? String,
              let role = userData["role"] as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])
        }
        
        return User(id: firebaseUser.uid, email: email, role: role)
    }
    
    func saveOrder(_ order: Order) async throws {
        print("FirebaseService: Saving order with total: \(order.total)")
        try await db.collection("orders").document(order.id).setData([
            "id": order.id,
            "items": order.items.map { ["itemId": $0.itemId, "quantity": $0.quantity] },
            "total": order.total,
            "status": order.status,
            "timestamp": Timestamp(date: order.timestamp),
            "cashierId": order.cashierId,
            "orderNumber": order.orderNumber as Any
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
}
