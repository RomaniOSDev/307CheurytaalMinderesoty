import Foundation

enum GroceryCategory: String, Codable, CaseIterable, Identifiable {
    case vegetables = "Vegetables"
    case proteins = "Proteins"
    case grains = "Grains"
    case dairy = "Dairy"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .vegetables: return "leaf.fill"
        case .proteins: return "flame.fill"
        case .grains: return "circle.grid.cross.fill"
        case .dairy: return "drop.fill"
        case .other: return "basket.fill"
        }
    }
}

struct GroceryItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var quantity: String
    var category: GroceryCategory
    var isPurchased: Bool = false
    var createdAt: Date = Date()
}
