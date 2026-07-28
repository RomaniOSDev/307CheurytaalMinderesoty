import Foundation
import SwiftUI
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var recipes: [Recipe] = RecipeCatalog.seed
    @Published var favoriteRecipes: [String] = []
    @Published var viewedRecipes: [String] = []
    @Published var recentIngredients: [String] = []
    @Published var groceryItems: [GroceryItem] = []
    @Published var activeTimers: [CookTimer] = []
    @Published var recipeNotes: [String: RecipeNote] = [:]
    @Published var mealPlan: [MealPlanEntry] = []
    @Published var challengeCompletedDate: String = ""
    @Published var stats: UserStats = UserStats()
    @Published var activityHistory: [DayActivity] = []
    @Published var achievementsUnlocked: Set<String> = []
    @Published var hasSeenOnboarding: Bool = false
    @Published var bannerTitle: String?
    @Published var showSuccessFlash: Bool = false

    private let defaults = UserDefaults.standard
    private let favoritesKey = "mm_favorites"
    private let viewedKey = "mm_viewed"
    private let recentKey = "mm_recent_ingredients"
    private let groceryKey = "mm_grocery"
    private let timersKey = "mm_timers"
    private let statsKey = "mm_stats"
    private let activityKey = "mm_activity_history"
    private let unlockedKey = "mm_unlocked"
    private let onboardingKey = "mm_onboarding"
    private let notesKey = "mm_recipe_notes"
    private let mealPlanKey = "mm_meal_plan"
    private let challengeKey = "mm_challenge_done"

    private var bannerQueue: [String] = []
    private var isShowingBanner = false
    private var sessionStart: Date?
    private var minuteTicker: Timer?
    private var cookSecondTicker: Timer?

    private init() {
        load()
        recipes = RecipeCatalog.seed
        startSessionTracking()
        NotificationService.shared.requestAuthorizationIfNeeded()
    }

    // MARK: - Recipes

    func isFavorite(_ recipeId: String) -> Bool {
        favoriteRecipes.contains(recipeId)
    }

    func toggleFavorite(_ recipeId: String) {
        if let idx = favoriteRecipes.firstIndex(of: recipeId) {
            favoriteRecipes.remove(at: idx)
            HapticService.light()
        } else {
            favoriteRecipes.append(recipeId)
            stats.favouritesAdded += 1
            flashSuccess()
            evaluateAchievements()
            HapticService.medium()
            HapticService.play(1104)
            completeChallengeIfNeeded(.addFavorite)
        }
        recordActivity()
        persist()
    }

    func markRecipeViewed(_ recipeId: String) {
        stats.recipesViewed += 1
        bumpToday(\.recipesViewed)
        if !viewedRecipes.contains(recipeId) {
            viewedRecipes.append(recipeId)
        }
        if let recipe = recipes.first(where: { $0.id == recipeId }) {
            for ingredient in recipe.ingredients.reversed() {
                recentIngredients.removeAll { $0.caseInsensitiveCompare(ingredient) == .orderedSame }
                recentIngredients.insert(ingredient, at: 0)
            }
            if recentIngredients.count > 20 {
                recentIngredients = Array(recentIngredients.prefix(20))
            }
        }
        recordActivity()
        evaluateAchievements()
        completeChallengeIfNeeded(.viewRecipe)
        persist()
    }

    func markCookModeStarted() {
        completeChallengeIfNeeded(.cookMode)
        persist()
    }

    func recipesMatching(
        query: String,
        favoritesOnly: Bool = false,
        fromCart: Bool = false,
        vegetarianOnly: Bool = false,
        quickOnly: Bool = false
    ) -> [Recipe] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return recipes.filter { recipe in
            if favoritesOnly && !favoriteRecipes.contains(recipe.id) { return false }
            if vegetarianOnly && !recipe.isVegetarian { return false }
            if quickOnly && recipe.cookMinutes > 30 { return false }
            if fromCart && !recipeMatchesCart(recipe) { return false }
            guard !q.isEmpty else { return true }
            let hay = ([recipe.name] + recipe.ingredients + recipe.tags).joined(separator: " ").lowercased()
            return hay.contains(q)
        }
    }

    func recipeMatchesCart(_ recipe: Recipe) -> Bool {
        let cartNames = groceryItems.map { $0.name.lowercased() }
        guard !cartNames.isEmpty else { return false }
        return recipe.ingredients.contains { ingredient in
            let lower = ingredient.lowercased()
            return cartNames.contains { cart in
                lower.contains(cart) || cart.contains(lower)
            }
        }
    }

    // MARK: - Recipe notes / rating

    func note(for recipeId: String) -> RecipeNote {
        recipeNotes[recipeId] ?? RecipeNote(recipeId: recipeId)
    }

    func updateNote(recipeId: String, text: String) {
        var entry = note(for: recipeId)
        entry.note = text
        recipeNotes[recipeId] = entry
        persist()
    }

    func updateRating(recipeId: String, rating: Int) {
        var entry = note(for: recipeId)
        entry.rating = max(0, min(5, rating))
        recipeNotes[recipeId] = entry
        persist()
        HapticService.light()
    }

    func updateLiked(recipeId: String, liked: Bool?) {
        var entry = note(for: recipeId)
        entry.liked = liked
        recipeNotes[recipeId] = entry
        persist()
        HapticService.light()
    }

    // MARK: - Grocery

    @discardableResult
    func addGroceryItem(name: String, quantity: String, category: GroceryCategory) -> GroceryItem? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let qty = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = GroceryItem(
            name: trimmed,
            quantity: qty.isEmpty ? "1" : qty,
            category: category
        )
        groceryItems.insert(item, at: 0)
        recordActivity()
        completeChallengeIfNeeded(.addGrocery)
        persist()
        flashSuccess()
        HapticService.medium()
        HapticService.play(1104)
        return item
    }

    @discardableResult
    func addRecipeIngredientsToCart(_ recipe: Recipe) -> Int {
        var added = 0
        for ingredient in recipe.ingredients {
            let trimmed = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let exists = groceryItems.contains {
                $0.name.caseInsensitiveCompare(trimmed) == .orderedSame
            }
            guard !exists else { continue }
            let item = GroceryItem(
                name: trimmed,
                quantity: "1",
                category: GroceryCategory.heuristic(for: trimmed)
            )
            groceryItems.insert(item, at: 0)
            added += 1
        }
        guard added > 0 else { return 0 }
        recordActivity()
        completeChallengeIfNeeded(.addGrocery)
        persist()
        flashSuccess()
        HapticService.medium()
        HapticService.play(1104)
        return added
    }

    func togglePurchased(_ item: GroceryItem) {
        guard let idx = groceryItems.firstIndex(where: { $0.id == item.id }) else { return }
        groceryItems[idx].isPurchased.toggle()
        let purchased = groceryItems[idx].isPurchased
        if purchased && !groceryItems.isEmpty && groceryItems.allSatisfy(\.isPurchased) {
            stats.listsCompleted += 1
            bumpToday(\.listsCompleted)
            evaluateAchievements()
            flashSuccess()
            HapticService.success()
        } else {
            HapticService.light()
        }
        recordActivity()
        persist()
    }

    func deleteGroceryItem(_ item: GroceryItem) {
        groceryItems.removeAll { $0.id == item.id }
        persist()
        HapticService.warning()
    }

    func shareListText() -> String {
        var lines = ["Grocery List"]
        for category in GroceryCategory.allCases {
            let items = groceryItems.filter { $0.category == category }
            guard !items.isEmpty else { continue }
            lines.append("")
            lines.append("\(category.rawValue):")
            for item in items {
                let mark = item.isPurchased ? "✓" : "○"
                lines.append("\(mark) \(item.name) — \(item.quantity)")
            }
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Timers

    @discardableResult
    func addTimer(dishName: String, minutes: Int) -> CookTimer? {
        let name = dishName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, minutes > 0 else { return nil }
        NotificationService.shared.requestAuthorizationIfNeeded()
        let total = minutes * 60
        var timer = CookTimer(
            dishName: name,
            totalSeconds: total,
            remainingSeconds: total,
            isRunning: true
        )
        timer.endsAt = Date().addingTimeInterval(TimeInterval(total))
        activeTimers.insert(timer, at: 0)
        recordActivity()
        persist()
        flashSuccess()
        HapticService.medium()
        HapticService.play(1104)
        return timer
    }

    func toggleTimerPause(_ id: UUID) {
        guard let idx = activeTimers.firstIndex(where: { $0.id == id }) else { return }
        guard !activeTimers[idx].isFinished else { return }
        activeTimers[idx].isRunning.toggle()
        if activeTimers[idx].isRunning {
            activeTimers[idx].endsAt = Date().addingTimeInterval(TimeInterval(activeTimers[idx].remainingSeconds))
            NotificationService.shared.cancelTimerNotification(id: id)
        } else {
            activeTimers[idx].endsAt = nil
            NotificationService.shared.cancelTimerNotification(id: id)
        }
        persist()
        HapticService.light()
    }

    func resetTimer(_ id: UUID) {
        guard let idx = activeTimers.firstIndex(where: { $0.id == id }) else { return }
        activeTimers[idx].remainingSeconds = activeTimers[idx].totalSeconds
        activeTimers[idx].isRunning = false
        activeTimers[idx].isFinished = false
        activeTimers[idx].endsAt = nil
        NotificationService.shared.cancelTimerNotification(id: id)
        persist()
        HapticService.medium()
    }

    func deleteTimer(_ id: UUID) {
        NotificationService.shared.cancelTimerNotification(id: id)
        activeTimers.removeAll { $0.id == id }
        persist()
        HapticService.warning()
    }

    func tickTimers(by seconds: Int = 1) {
        var changed = false
        for idx in activeTimers.indices {
            guard activeTimers[idx].isRunning, !activeTimers[idx].isFinished else { continue }
            if let endsAt = activeTimers[idx].endsAt {
                let remaining = max(0, Int(ceil(endsAt.timeIntervalSinceNow)))
                if remaining != activeTimers[idx].remainingSeconds {
                    activeTimers[idx].remainingSeconds = remaining
                    changed = true
                }
            } else {
                let next = max(0, activeTimers[idx].remainingSeconds - seconds)
                if next != activeTimers[idx].remainingSeconds {
                    activeTimers[idx].remainingSeconds = next
                    changed = true
                }
            }
            if activeTimers[idx].remainingSeconds == 0 {
                finishTimer(at: idx)
                changed = true
            }
        }
        if changed { persist() }
    }

    private func finishTimer(at idx: Int) {
        activeTimers[idx].isRunning = false
        activeTimers[idx].endsAt = nil
        NotificationService.shared.cancelTimerNotification(id: activeTimers[idx].id)
        guard !activeTimers[idx].isFinished else { return }
        activeTimers[idx].isFinished = true
        stats.timersFinished += 1
        bumpToday(\.timersFinished)
        evaluateAchievements()
        completeChallengeIfNeeded(.finishTimer)
        flashSuccess()
        HapticService.success()
    }

    /// Schedules local notifications for running timers when entering background.
    /// Timers keep `isRunning` and `endsAt` so foreground sync can resume accurately.
    func pauseAllTimersForBackground() {
        var changed = false
        for idx in activeTimers.indices where activeTimers[idx].isRunning && !activeTimers[idx].isFinished {
            if activeTimers[idx].endsAt == nil {
                activeTimers[idx].endsAt = Date().addingTimeInterval(TimeInterval(activeTimers[idx].remainingSeconds))
                changed = true
            }
            let remainingFromEnd = max(1, Int(ceil(activeTimers[idx].endsAt?.timeIntervalSinceNow ?? TimeInterval(activeTimers[idx].remainingSeconds))))
            activeTimers[idx].remainingSeconds = remainingFromEnd
            changed = true
            NotificationService.shared.scheduleTimerFinished(
                id: activeTimers[idx].id,
                dishName: activeTimers[idx].dishName,
                afterSeconds: remainingFromEnd
            )
        }
        if changed { persist() }
    }

    func syncTimersOnForeground() {
        var changed = false
        let now = Date()
        for idx in activeTimers.indices {
            guard activeTimers[idx].isRunning, !activeTimers[idx].isFinished else { continue }
            guard let endsAt = activeTimers[idx].endsAt else { continue }
            let remaining = max(0, Int(ceil(endsAt.timeIntervalSince(now))))
            if remaining != activeTimers[idx].remainingSeconds {
                activeTimers[idx].remainingSeconds = remaining
                changed = true
            }
            NotificationService.shared.cancelTimerNotification(id: activeTimers[idx].id)
            if remaining == 0 {
                finishTimer(at: idx)
                changed = true
            }
        }
        if changed { persist() }
    }

    // MARK: - Meal plan

    func mealPlanEntry(dayKey: String, meal: MealSlot) -> MealPlanEntry? {
        mealPlan.first { $0.dayKey == dayKey && $0.meal == meal }
    }

    func setMealPlan(dayKey: String, meal: MealSlot, recipeId: String?) {
        if let idx = mealPlan.firstIndex(where: { $0.dayKey == dayKey && $0.meal == meal }) {
            if let recipeId {
                mealPlan[idx].recipeId = recipeId
            } else {
                mealPlan.remove(at: idx)
            }
        } else if let recipeId {
            mealPlan.append(MealPlanEntry(dayKey: dayKey, meal: meal, recipeId: recipeId))
        }
        persist()
        HapticService.light()
    }

    func upcomingPlanDays(count: Int = 7) -> [Date] {
        let calendar = Calendar.current
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: Date())) }
    }

    // MARK: - Daily challenge

    var isChallengeCompleteToday: Bool {
        challengeCompletedDate == DailyContent.dayKey()
    }

    func completeChallengeIfNeeded(_ kind: DailyChallengeKind) {
        guard !isChallengeCompleteToday else { return }
        let challenge = DailyContent.challengeForToday()
        guard challenge.kind == kind else { return }
        challengeCompletedDate = DailyContent.dayKey()
        flashSuccess()
        HapticService.success()
    }

    // MARK: - Onboarding / Reset / Session

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: onboardingKey)
        HapticService.success()
    }

    func resetAll() {
        favoriteRecipes = []
        viewedRecipes = []
        recentIngredients = []
        groceryItems = []
        activeTimers = []
        recipeNotes = [:]
        mealPlan = []
        challengeCompletedDate = ""
        stats = UserStats()
        activityHistory = []
        achievementsUnlocked = []
        bannerTitle = nil
        bannerQueue.removeAll()
        isShowingBanner = false
        recipes = RecipeCatalog.seed
        NotificationService.shared.cancelAllTimerNotifications()
        persist()
        NotificationCenter.default.post(name: .dataReset, object: nil)
        HapticService.warning()
    }

    func activityLastDays(_ count: Int) -> [DayActivity] {
        let formatter = Self.dayFormatter
        let calendar = Calendar.current
        var result: [DayActivity] = []
        for offset in (0..<count).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let key = formatter.string(from: date)
            if let existing = activityHistory.first(where: { $0.date == key }) {
                result.append(existing)
            } else {
                result.append(DayActivity(date: key))
            }
        }
        return result
    }

    func noteSessionBecameActive() {
        if sessionStart == nil {
            sessionStart = Date()
            stats.totalSessionsCompleted += 1
            recordActivity()
            persist()
        }
        syncTimersOnForeground()
        resumeMinuteTicker()
        resumeCookSecondTicker()
    }

    func noteSessionBecameInactive() {
        flushSessionMinutes()
        minuteTicker?.invalidate()
        minuteTicker = nil
        stopCookSecondTicker()
        sessionStart = nil
        pauseAllTimersForBackground()
    }

    // MARK: - Achievements

    func evaluateAchievements() {
        for kind in AchievementKind.allCases {
            guard kind.isUnlocked(stats: stats) else { continue }
            let key = kind.rawValue
            guard !achievementsUnlocked.contains(key) else { continue }
            achievementsUnlocked.insert(key)
            enqueueBanner(kind.title)
        }
        persist()
    }

    private func enqueueBanner(_ title: String) {
        bannerQueue.append(title)
        presentNextBannerIfNeeded()
    }

    private func presentNextBannerIfNeeded() {
        guard !isShowingBanner, let next = bannerQueue.first else { return }
        bannerQueue.removeFirst()
        isShowingBanner = true
        HapticService.success()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            bannerTitle = next
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            withAnimation(.easeOut(duration: 0.35)) {
                self?.bannerTitle = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self?.isShowingBanner = false
                self?.presentNextBannerIfNeeded()
            }
        }
    }

    func flashSuccess() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showSuccessFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.showSuccessFlash = false
            }
        }
    }

    // MARK: - Persistence helpers

    private func startSessionTracking() {
        noteSessionBecameActive()
    }

    private func resumeMinuteTicker() {
        minuteTicker?.invalidate()
        minuteTicker = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.stats.totalMinutesUsed += 1
            self?.bumpToday(\.minutesUsed)
            self?.persist()
        }
    }

    private func resumeCookSecondTicker() {
        cookSecondTicker?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tickTimers(by: 1)
        }
        RunLoop.main.add(timer, forMode: .common)
        cookSecondTicker = timer
    }

    private func stopCookSecondTicker() {
        cookSecondTicker?.invalidate()
        cookSecondTicker = nil
    }

    private func flushSessionMinutes() {
        guard let start = sessionStart else { return }
        let elapsed = Int(Date().timeIntervalSince(start) / 60)
        if elapsed > 0 {
            stats.totalMinutesUsed += elapsed
            bumpToday(\.minutesUsed, by: elapsed)
            persist()
        }
    }

    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func bumpToday(_ keyPath: WritableKeyPath<DayActivity, Int>, by amount: Int = 1) {
        let today = Self.dayFormatter.string(from: Date())
        if let idx = activityHistory.firstIndex(where: { $0.date == today }) {
            activityHistory[idx][keyPath: keyPath] += amount
        } else {
            var day = DayActivity(date: today)
            day[keyPath: keyPath] += amount
            activityHistory.append(day)
        }
        if activityHistory.count > 90 {
            activityHistory = Array(activityHistory.suffix(90))
        }
    }

    private func recordActivity() {
        let today = Self.dayFormatter.string(from: Date())
        if stats.lastActivityDate.isEmpty {
            stats.streakDays = 1
            stats.lastActivityDate = today
            return
        }
        if stats.lastActivityDate == today { return }
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           Self.dayFormatter.string(from: yesterday) == stats.lastActivityDate {
            stats.streakDays += 1
        } else {
            stats.streakDays = 1
        }
        stats.lastActivityDate = today
    }

    private func load() {
        hasSeenOnboarding = defaults.bool(forKey: onboardingKey)
        if let data = defaults.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            favoriteRecipes = decoded
        }
        if let data = defaults.data(forKey: viewedKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            viewedRecipes = decoded
        }
        if let data = defaults.data(forKey: recentKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            recentIngredients = decoded
        }
        if let data = defaults.data(forKey: groceryKey),
           let decoded = try? JSONDecoder().decode([GroceryItem].self, from: data) {
            groceryItems = decoded
        }
        if let data = defaults.data(forKey: timersKey),
           let decoded = try? JSONDecoder().decode([CookTimer].self, from: data) {
            activeTimers = decoded
        }
        if let data = defaults.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([String: RecipeNote].self, from: data) {
            recipeNotes = decoded
        }
        if let data = defaults.data(forKey: mealPlanKey),
           let decoded = try? JSONDecoder().decode([MealPlanEntry].self, from: data) {
            mealPlan = decoded
        }
        challengeCompletedDate = defaults.string(forKey: challengeKey) ?? ""
        if let data = defaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(UserStats.self, from: data) {
            stats = decoded
        }
        if let data = defaults.data(forKey: activityKey),
           let decoded = try? JSONDecoder().decode([DayActivity].self, from: data) {
            activityHistory = decoded
        }
        if let arr = defaults.array(forKey: unlockedKey) as? [String] {
            achievementsUnlocked = Set(arr)
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(favoriteRecipes) {
            defaults.set(data, forKey: favoritesKey)
        }
        if let data = try? JSONEncoder().encode(viewedRecipes) {
            defaults.set(data, forKey: viewedKey)
        }
        if let data = try? JSONEncoder().encode(recentIngredients) {
            defaults.set(data, forKey: recentKey)
        }
        if let data = try? JSONEncoder().encode(groceryItems) {
            defaults.set(data, forKey: groceryKey)
        }
        if let data = try? JSONEncoder().encode(activeTimers) {
            defaults.set(data, forKey: timersKey)
        }
        if let data = try? JSONEncoder().encode(recipeNotes) {
            defaults.set(data, forKey: notesKey)
        }
        if let data = try? JSONEncoder().encode(mealPlan) {
            defaults.set(data, forKey: mealPlanKey)
        }
        defaults.set(challengeCompletedDate, forKey: challengeKey)
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: statsKey)
        }
        if let data = try? JSONEncoder().encode(activityHistory) {
            defaults.set(data, forKey: activityKey)
        }
        defaults.set(Array(achievementsUnlocked), forKey: unlockedKey)
        defaults.set(hasSeenOnboarding, forKey: onboardingKey)
    }
}
