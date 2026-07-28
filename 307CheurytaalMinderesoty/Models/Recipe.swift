import Foundation

struct IngredientSwap: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var original: String
    var alternative: String
    var note: String
}

struct Recipe: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var name: String
    var cookMinutes: Int
    var isVegetarian: Bool
    var ingredients: [String]
    var steps: [String]
    var swaps: [IngredientSwap]
    var imageName: String
    var tags: [String]
    var baseServings: Int = 2

    var cookTimeLabel: String {
        if cookMinutes < 60 { return "\(cookMinutes) min" }
        let hours = cookMinutes / 60
        let mins = cookMinutes % 60
        return mins == 0 ? "\(hours)h" : "\(hours)h \(mins)m"
    }

    func scaledIngredientDisplay(_ ingredient: String, servings: Int) -> String {
        let base = max(1, baseServings)
        let target = max(1, servings)
        guard target != base else { return ingredient }

        let pattern = #"^(\d+(\.\d+)?)\s+(.*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: ingredient, range: NSRange(ingredient.startIndex..., in: ingredient)),
              let numRange = Range(match.range(at: 1), in: ingredient),
              let restRange = Range(match.range(at: 3), in: ingredient),
              let value = Double(ingredient[numRange]) else {
            return "\(ingredient) · for \(target) servings"
        }

        let scaled = value * Double(target) / Double(base)
        let formatted: String
        if abs(scaled - scaled.rounded()) < 0.01 {
            formatted = String(Int(scaled.rounded()))
        } else {
            formatted = String(format: "%.1f", scaled)
        }
        return "\(formatted) \(ingredient[restRange])"
    }
}

extension GroceryCategory {
    static func heuristic(for ingredient: String) -> GroceryCategory {
        let lower = ingredient.lowercased()
        let proteins = ["meat", "fish", "chicken", "salmon", "shrimp", "turkey", "beef", "egg", "scallop", "trout"]
        if proteins.contains(where: { lower.contains($0) }) { return .proteins }

        let dairy = ["milk", "cheese", "butter", "yogurt", "parmesan", "mozzarella", "feta", "ghee", "cream"]
        if dairy.contains(where: { lower.contains($0) }) { return .dairy }

        let grains = ["rice", "pasta", "quinoa", "tortilla", "bread", "flatbread", "arborio", "farro", "pita"]
        if grains.contains(where: { lower.contains($0) }) { return .grains }

        let vegetables = [
            "tomato", "garlic", "basil", "broccoli", "pepper", "carrot", "ginger", "onion",
            "mushroom", "spinach", "kale", "zucchini", "avocado", "corn", "pea", "lemon",
            "lime", "herb", "parsley", "thyme", "oregano", "chili", "cucumber", "lettuce",
            "celery", "potato", "bean", "chickpea", "lentil"
        ]
        if vegetables.contains(where: { lower.contains($0) }) { return .vegetables }

        return .other
    }
}

enum RecipeCatalog {
    static let seed: [Recipe] = [
        Recipe(
            id: "r1",
            name: "Herb Tomato Pasta",
            cookMinutes: 25,
            isVegetarian: true,
            ingredients: ["Pasta", "Tomatoes", "Garlic", "Basil", "Olive oil", "Parmesan"],
            steps: [
                "Boil pasta in salted water until al dente.",
                "Sauté garlic in olive oil until fragrant.",
                "Add chopped tomatoes and simmer 8 minutes.",
                "Toss pasta with sauce, basil, and cheese."
            ],
            swaps: [
                IngredientSwap(original: "Parmesan", alternative: "Nutritional yeast", note: "Keeps it dairy-free."),
                IngredientSwap(original: "Basil", alternative: "Parsley", note: "Milder herbal finish.")
            ],
            imageName: "img_card",
            tags: ["pasta", "quick", "italian"],
            baseServings: 2
        ),
        Recipe(
            id: "r2",
            name: "Lemon Garlic Chicken",
            cookMinutes: 35,
            isVegetarian: false,
            ingredients: ["Chicken thighs", "Lemon", "Garlic", "Thyme", "Butter", "Salt"],
            steps: [
                "Season chicken with salt, pepper, and thyme.",
                "Sear in butter until golden on both sides.",
                "Add garlic and lemon juice, cover, and cook through.",
                "Rest 5 minutes, then spoon pan juices over the top."
            ],
            swaps: [
                IngredientSwap(original: "Butter", alternative: "Olive oil", note: "Lighter pan sauce."),
                IngredientSwap(original: "Chicken thighs", alternative: "Chicken breast", note: "Reduce cook time slightly.")
            ],
            imageName: "img_banner",
            tags: ["chicken", "protein", "dinner"],
            baseServings: 2
        ),
        Recipe(
            id: "r3",
            name: "Veggie Stir Fry Bowl",
            cookMinutes: 20,
            isVegetarian: true,
            ingredients: ["Broccoli", "Bell pepper", "Carrot", "Soy sauce", "Ginger", "Rice"],
            steps: [
                "Cook rice and keep warm.",
                "Stir-fry vegetables on high heat for 4–5 minutes.",
                "Add grated ginger and soy sauce.",
                "Serve over rice with extra sauce."
            ],
            swaps: [
                IngredientSwap(original: "Soy sauce", alternative: "Tamari", note: "Gluten-free option."),
                IngredientSwap(original: "Rice", alternative: "Quinoa", note: "Extra protein boost.")
            ],
            imageName: "img_accent",
            tags: ["stir-fry", "vegan-friendly", "quick"],
            baseServings: 2
        ),
        Recipe(
            id: "r4",
            name: "Creamy Mushroom Risotto",
            cookMinutes: 40,
            isVegetarian: true,
            ingredients: ["Arborio rice", "Mushrooms", "Onion", "Vegetable broth", "Parmesan", "Butter"],
            steps: [
                "Sauté onion and mushrooms in butter.",
                "Toast rice for 1 minute.",
                "Add warm broth ladle by ladle, stirring.",
                "Finish with Parmesan and rest briefly."
            ],
            swaps: [
                IngredientSwap(original: "Arborio rice", alternative: "Short-grain rice", note: "Slightly less creamy."),
                IngredientSwap(original: "Butter", alternative: "Olive oil", note: "Dairy-light version.")
            ],
            imageName: "img_card",
            tags: ["risotto", "comfort", "italian"],
            baseServings: 2
        ),
        Recipe(
            id: "r5",
            name: "Spiced Black Bean Tacos",
            cookMinutes: 22,
            isVegetarian: true,
            ingredients: ["Black beans", "Tortillas", "Cumin", "Lime", "Avocado", "Onion"],
            steps: [
                "Warm beans with cumin and onion.",
                "Heat tortillas until soft.",
                "Fill with beans and sliced avocado.",
                "Finish with lime juice and crunchy toppings."
            ],
            swaps: [
                IngredientSwap(original: "Black beans", alternative: "Pinto beans", note: "Similar texture."),
                IngredientSwap(original: "Avocado", alternative: "Guacamole", note: "Creamier finish.")
            ],
            imageName: "img_banner",
            tags: ["tacos", "mexican", "weeknight"],
            baseServings: 2
        ),
        Recipe(
            id: "r6",
            name: "Honey Soy Salmon",
            cookMinutes: 28,
            isVegetarian: false,
            ingredients: ["Salmon fillets", "Honey", "Soy sauce", "Garlic", "Sesame seeds", "Green onion"],
            steps: [
                "Whisk honey, soy, and garlic into a glaze.",
                "Brush salmon and roast until flaky.",
                "Broil briefly for caramelized edges.",
                "Top with sesame seeds and green onion."
            ],
            swaps: [
                IngredientSwap(original: "Honey", alternative: "Maple syrup", note: "Slightly smokier sweetness."),
                IngredientSwap(original: "Salmon", alternative: "Trout", note: "Similar cook time.")
            ],
            imageName: "img_accent",
            tags: ["seafood", "glazed", "protein"],
            baseServings: 2
        ),
        Recipe(
            id: "r7",
            name: "Chickpea Coconut Curry",
            cookMinutes: 30,
            isVegetarian: true,
            ingredients: ["Chickpeas", "Coconut milk", "Curry powder", "Tomato", "Spinach", "Onion"],
            steps: [
                "Sauté onion until soft.",
                "Add curry powder and toast briefly.",
                "Stir in chickpeas, tomato, and coconut milk.",
                "Fold in spinach and simmer until wilted."
            ],
            swaps: [
                IngredientSwap(original: "Chickpeas", alternative: "Lentils", note: "Softer, earthier curry."),
                IngredientSwap(original: "Spinach", alternative: "Kale", note: "Heartier greens.")
            ],
            imageName: "img_card",
            tags: ["curry", "one-pot", "vegan-friendly"],
            baseServings: 2
        ),
        Recipe(
            id: "r8",
            name: "Classic Beef Chili",
            cookMinutes: 45,
            isVegetarian: false,
            ingredients: ["Ground beef", "Kidney beans", "Tomato", "Chili powder", "Onion", "Garlic"],
            steps: [
                "Brown beef with onion and garlic.",
                "Stir in spices and tomatoes.",
                "Add beans and simmer 25 minutes.",
                "Taste, adjust salt, and serve hot."
            ],
            swaps: [
                IngredientSwap(original: "Ground beef", alternative: "Turkey mince", note: "Leaner chili."),
                IngredientSwap(original: "Kidney beans", alternative: "Black beans", note: "Slightly sweeter.")
            ],
            imageName: "img_banner",
            tags: ["chili", "hearty", "batch-cook"],
            baseServings: 2
        ),
        Recipe(
            id: "r9",
            name: "Caprese Grain Bowl",
            cookMinutes: 18,
            isVegetarian: true,
            ingredients: ["Quinoa", "Tomato", "Mozzarella", "Basil", "Balsamic", "Olive oil"],
            steps: [
                "Cook quinoa and cool slightly.",
                "Toss with tomatoes and mozzarella.",
                "Dress with olive oil and balsamic.",
                "Finish with torn basil leaves."
            ],
            swaps: [
                IngredientSwap(original: "Quinoa", alternative: "Farro", note: "Chewier bite."),
                IngredientSwap(original: "Mozzarella", alternative: "Feta", note: "Saltier contrast.")
            ],
            imageName: "img_accent",
            tags: ["bowl", "fresh", "lunch"],
            baseServings: 2
        ),
        Recipe(
            id: "r10",
            name: "Shrimp Garlic Skillet",
            cookMinutes: 15,
            isVegetarian: false,
            ingredients: ["Shrimp", "Garlic", "Butter", "Parsley", "Lemon", "Chili flakes"],
            steps: [
                "Pat shrimp dry and season lightly.",
                "Sauté garlic in butter until aromatic.",
                "Cook shrimp 2 minutes per side.",
                "Finish with lemon, parsley, and chili flakes."
            ],
            swaps: [
                IngredientSwap(original: "Shrimp", alternative: "Scallops", note: "Similar sear time."),
                IngredientSwap(original: "Butter", alternative: "Ghee", note: "Nutty aroma.")
            ],
            imageName: "img_card",
            tags: ["seafood", "fast", "skillet"],
            baseServings: 2
        ),
        Recipe(
            id: "r11",
            name: "Roasted Veggie Flatbread",
            cookMinutes: 32,
            isVegetarian: true,
            ingredients: ["Flatbread", "Zucchini", "Pepper", "Feta", "Olive oil", "Oregano"],
            steps: [
                "Roast sliced vegetables until tender.",
                "Brush flatbread with olive oil.",
                "Top with veggies, feta, and oregano.",
                "Bake until edges crisp, then slice."
            ],
            swaps: [
                IngredientSwap(original: "Feta", alternative: "Goat cheese", note: "Creamier topping."),
                IngredientSwap(original: "Flatbread", alternative: "Pita", note: "Softer base.")
            ],
            imageName: "img_banner",
            tags: ["flatbread", "roast", "shareable"],
            baseServings: 2
        ),
        Recipe(
            id: "r12",
            name: "Turkey Veggie Skillet",
            cookMinutes: 26,
            isVegetarian: false,
            ingredients: ["Ground turkey", "Zucchini", "Corn", "Tomato", "Paprika", "Onion"],
            steps: [
                "Brown turkey with onion and paprika.",
                "Add diced zucchini and corn.",
                "Stir in tomatoes and simmer briefly.",
                "Season to taste and serve warm."
            ],
            swaps: [
                IngredientSwap(original: "Ground turkey", alternative: "Chicken mince", note: "Same cook method."),
                IngredientSwap(original: "Corn", alternative: "Peas", note: "Sweet green pop.")
            ],
            imageName: "img_accent",
            tags: ["skillet", "protein", "weeknight"],
            baseServings: 2
        )
    ]
}
