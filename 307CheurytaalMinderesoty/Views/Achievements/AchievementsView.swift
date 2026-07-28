import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: AppDataStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                SoftCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image("img_accent")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Kitchen Badges")
                                    .font(.headline)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text("Decorative milestones — nothing is locked.")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .lineLimit(2)
                            }
                        }
                        HStack {
                            metric("Viewed", store.stats.recipesViewed)
                            metric("Favorites", store.stats.favouritesAdded)
                            metric("Timers", store.stats.timersFinished)
                            metric("Lists", store.stats.listsCompleted)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(AchievementKind.allCases, id: \.rawValue) { kind in
                        achievementCard(kind)
                            .frame(maxWidth: .infinity, alignment: .top)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .dismissKeyboardOnTap()
        }
    }

    private func metric(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func achievementCard(_ kind: AchievementKind) -> some View {
        let unlocked = store.achievementsUnlocked.contains(kind.rawValue) || kind.isUnlocked(stats: store.stats)
        let progress = min(kind.progress(stats: store.stats), kind.goal)
        return SoftCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: kind.icon)
                    .font(.title2)
                    .foregroundStyle(unlocked ? Color("AppPrimary") : Color("AppTextSecondary"))
                    .shadow(color: unlocked ? Color("AppPrimary").opacity(0.45) : .clear, radius: 8)
                Text(kind.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(kind.detail)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                ProgressView(value: Double(progress), total: Double(kind.goal))
                    .tint(Color("AppAccent"))
                Text("\(progress)/\(kind.goal)")
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(unlocked ? 1 : 0.72)
        }
    }
}
