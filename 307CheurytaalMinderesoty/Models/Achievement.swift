import Foundation

enum AchievementKind: String, Codable, CaseIterable {
    case firstRecipe
    case creativeCook
    case pantryPro
    case multitasker
    case recipeExplorer
    case gettingGoing
    case powerUser
    case activeUser

    var title: String {
        switch self {
        case .firstRecipe: return "First Recipe"
        case .creativeCook: return "Creative Cook"
        case .pantryPro: return "Pantry Pro"
        case .multitasker: return "Multitasker"
        case .recipeExplorer: return "Recipe Explorer"
        case .gettingGoing: return "Getting Going"
        case .powerUser: return "Power User"
        case .activeUser: return "Active User"
        }
    }

    var detail: String {
        switch self {
        case .firstRecipe: return "View your first recipe"
        case .creativeCook: return "Browse 5 recipes"
        case .pantryPro: return "Favourite 10 recipes"
        case .multitasker: return "Finish 3 cook timers"
        case .recipeExplorer: return "Favourite 20 recipes"
        case .gettingGoing: return "View 10 recipes"
        case .powerUser: return "View 50 recipes"
        case .activeUser: return "Complete 10 grocery lists"
        }
    }

    var icon: String {
        switch self {
        case .firstRecipe: return "book.fill"
        case .creativeCook: return "lightbulb.fill"
        case .pantryPro: return "carrot.fill"
        case .multitasker: return "timer"
        case .recipeExplorer: return "heart.fill"
        case .gettingGoing: return "figure.walk"
        case .powerUser: return "bolt.fill"
        case .activeUser: return "checklist"
        }
    }

    var goal: Int {
        switch self {
        case .firstRecipe: return 1
        case .creativeCook: return 5
        case .pantryPro: return 10
        case .multitasker: return 3
        case .recipeExplorer: return 20
        case .gettingGoing: return 10
        case .powerUser: return 50
        case .activeUser: return 10
        }
    }

    func progress(stats: UserStats) -> Int {
        switch self {
        case .firstRecipe, .creativeCook, .gettingGoing, .powerUser:
            return stats.recipesViewed
        case .pantryPro, .recipeExplorer:
            return stats.favouritesAdded
        case .multitasker:
            return stats.timersFinished
        case .activeUser:
            return stats.listsCompleted
        }
    }

    func isUnlocked(stats: UserStats) -> Bool {
        progress(stats: stats) >= goal
    }
}

struct UserStats: Codable, Equatable {
    var recipesViewed: Int = 0
    var favouritesAdded: Int = 0
    var timersFinished: Int = 0
    var listsCompleted: Int = 0
    var totalSessionsCompleted: Int = 0
    var totalMinutesUsed: Int = 0
    var streakDays: Int = 0
    var lastActivityDate: String = ""
}

struct DayActivity: Codable, Equatable, Identifiable {
    var date: String
    var recipesViewed: Int = 0
    var timersFinished: Int = 0
    var listsCompleted: Int = 0
    var minutesUsed: Int = 0

    var id: String { date }

    var totalActions: Int {
        recipesViewed + timersFinished + listsCompleted
    }
}

extension Notification.Name {
    static let dataReset = Notification.Name("mm_dataReset")
}
