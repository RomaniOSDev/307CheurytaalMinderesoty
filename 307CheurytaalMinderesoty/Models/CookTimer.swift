import Foundation

struct CookTimer: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var dishName: String
    var totalSeconds: Int
    var remainingSeconds: Int
    var isRunning: Bool
    var isFinished: Bool = false
    var createdAt: Date = Date()
    var endsAt: Date? = nil

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    var displayTime: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
