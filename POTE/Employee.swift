import FirebaseFirestore

struct Employee: Identifiable, Codable {
    @DocumentID var id: String?
    let employeeId: String
    let role: String
    let email: String?
    let firstName: String? // Added for displaying in MenuView
    let lastName: String?  // Added for displaying in MenuView
}
