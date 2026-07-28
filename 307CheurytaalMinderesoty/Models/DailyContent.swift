import Foundation

enum DailyChallengeKind: String, Codable {
    case viewRecipe
    case addFavorite
    case finishTimer
    case addGrocery
    case cookMode
}

struct DailyChallenge: Equatable {
    var kind: DailyChallengeKind
    var title: String
    var detail: String
}

enum DailyContent {
    static let tips: [String] = [
        "Salt pasta water until it tastes like the sea.",
        "Rest meat a few minutes before slicing for juicier cuts.",
        "Taste as you cook — seasoning builds in layers.",
        "Keep a sharp knife; it is safer and faster.",
        "Mise en place: prep ingredients before you start heating.",
        "A splash of acid brightens rich sauces.",
        "Don't overcrowd the pan — sear needs space.",
        "Save pasta water to loosen and bind sauces.",
        "Toast spices briefly to wake up their aroma.",
        "Let eggs come to room temperature for even cooking.",
        "Rinse rice until water runs clearer for fluffier grains.",
        "Warm tortillas or flatbread before serving.",
        "Finish dishes with fresh herbs for lift.",
        "Batch-cook grains for easy weekday bowls.",
        "Use residual heat to finish delicate fish.",
        "Balance sweet, salty, sour, and bitter in every plate.",
        "Chill mixing bowls for whipped cream or egg whites.",
        "Read the whole recipe once before you begin.",
        "Keep citrus nearby — lemon fixes almost anything.",
        "Clean as you go so plating feels calm."
    ]

    static func tipForToday(date: Date = Date()) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return tips[(day - 1) % tips.count]
    }

    static func challengeForToday(date: Date = Date()) -> DailyChallenge {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        switch day % 5 {
        case 0:
            return DailyChallenge(
                kind: .viewRecipe,
                title: "Browse a recipe",
                detail: "View 1 recipe today."
            )
        case 1:
            return DailyChallenge(
                kind: .addFavorite,
                title: "Heart a favorite",
                detail: "Save 1 recipe to favorites."
            )
        case 2:
            return DailyChallenge(
                kind: .finishTimer,
                title: "Finish a timer",
                detail: "Complete 1 cook timer."
            )
        case 3:
            return DailyChallenge(
                kind: .addGrocery,
                title: "Stock the cart",
                detail: "Add 1 item to your grocery cart."
            )
        default:
            return DailyChallenge(
                kind: .cookMode,
                title: "Start cook mode",
                detail: "Open cook mode for any recipe."
            )
        }
    }

    static func dayKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
