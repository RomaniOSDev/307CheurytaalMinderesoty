import SwiftUI

struct MealPlanSegmentView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var picking: PickTarget?
    @State private var appear = false

    private struct PickTarget: Identifiable {
        var id: String { "\(dayKey)-\(meal.rawValue)" }
        let dayKey: String
        let meal: MealSlot
    }

    private var days: [Date] {
        store.upcomingPlanDays(count: 7)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(days, id: \.self) { date in
                    dayCard(date)
                }
            }
            .padding(16)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 10)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appear = true }
        }
        .sheet(item: $picking) { target in
            RecipePickSheet(dayKey: target.dayKey, meal: target.meal)
                .environmentObject(store)
        }
    }

    private func dayCard(_ date: Date) -> some View {
        let key = AppDataStore.dayFormatter.string(from: date)
        return SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(dayTitle(date))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                ForEach(MealSlot.allCases) { meal in
                    mealRow(dayKey: key, meal: meal)
                }
            }
        }
    }

    private func mealRow(dayKey: String, meal: MealSlot) -> some View {
        let entry = store.mealPlanEntry(dayKey: dayKey, meal: meal)
        let recipe = store.recipes.first { $0.id == entry?.recipeId }
        return Button {
            HapticService.light()
            picking = PickTarget(dayKey: dayKey, meal: meal)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: meal == .lunch ? "sun.max.fill" : "moon.stars.fill")
                    .foregroundStyle(Color("AppAccent"))
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppTextSecondary"))
                    Text(recipe?.name ?? "Tap to pick a recipe")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(recipe == nil ? Color("AppTextSecondary") : Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                if recipe != nil {
                    Button {
                        store.setMealPlan(dayKey: dayKey, meal: meal, recipeId: nil)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func dayTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

struct RecipePickSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let dayKey: String
    let meal: MealSlot

    var body: some View {
        NavigationStack {
            List {
                Button("Clear slot") {
                    store.setMealPlan(dayKey: dayKey, meal: meal, recipeId: nil)
                    dismiss()
                }
                .foregroundStyle(Color.red.opacity(0.9))
                .listRowBackground(Color("AppSurface").opacity(0.55))

                ForEach(store.recipes) { recipe in
                    Button {
                        store.setMealPlan(dayKey: dayKey, meal: meal, recipeId: recipe.id)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.name)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .lineLimit(1)
                                Text(recipe.cookTimeLabel)
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            Spacer()
                            if store.mealPlanEntry(dayKey: dayKey, meal: meal)?.recipeId == recipe.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color("AppPrimary"))
                            }
                        }
                    }
                    .listRowBackground(Color("AppSurface").opacity(0.55))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .navigationTitle("Pick Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
