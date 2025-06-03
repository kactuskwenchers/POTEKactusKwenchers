import Foundation
import Combine

@MainActor
class MenuViewModel: ObservableObject {
    static let shared = MenuViewModel()
    @Published var items: [MenuItem] = []
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        fetchItems()
    }
    
    func fetchItems() {
        Task {
            do {
                let fetchedItems = try await FirebaseService.shared.fetchItems()
                self.items = fetchedItems
            } catch {
                print("MenuViewModel: Failed to fetch items: \(error)")
            }
        }
    }
    
    func getMenuItem(forId id: String) -> MenuItem? {
        items.first { $0.id == id }
    }
    
    func getItemName(forId id: String) -> String {
        getMenuItem(forId: id)?.name ?? "Unknown Item"
    }
}
