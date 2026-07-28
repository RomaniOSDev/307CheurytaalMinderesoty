import Foundation

enum MealSlot: String, Codable, CaseIterable, Identifiable {
    case lunch = "Lunch"
    case dinner = "Dinner"

    var id: String { rawValue }
}

struct MealPlanEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var dayKey: String
    var meal: MealSlot
    var recipeId: String?
}
