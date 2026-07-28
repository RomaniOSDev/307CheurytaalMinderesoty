import Foundation

struct RecipeNote: Codable, Equatable, Identifiable {
    var id: String { recipeId }
    var recipeId: String
    var note: String = ""
    var rating: Int = 0
    var liked: Bool? = nil
}
