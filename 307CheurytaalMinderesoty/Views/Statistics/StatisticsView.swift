import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject private var store: AppDataStore

    private var weekDays: [DayActivity] {
        store.activityLastDays(7)
    }

    private var categoryBreakdown: [(name: String, value: Int, color: Color)] {
        [
            ("Recipes", store.stats.recipesViewed, Color("AppPrimary")),
            ("Timers", store.stats.timersFinished, Color("AppAccent")),
            ("Lists", store.stats.listsCompleted, Color("AppPrimary").opacity(0.7)),
            ("Favorites", store.stats.favouritesAdded, Color("AppAccent").opacity(0.75))
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryGrid

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Activity · 7 days")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text("Recipes, timers, and grocery lists per day.")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))

                            Chart(weekDays) { day in
                                BarMark(
                                    x: .value("Day", shortDayLabel(day.date)),
                                    y: .value("Actions", day.totalActions)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color("AppPrimary"), Color("AppAccent")],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(6)
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: 180)
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Minutes cooking")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text("Time spent in the app this week.")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))

                            Chart(weekDays) { day in
                                LineMark(
                                    x: .value("Day", shortDayLabel(day.date)),
                                    y: .value("Minutes", day.minutesUsed)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color("AppAccent"))
                                .symbol(Circle())
                                .symbolSize(40)

                                AreaMark(
                                    x: .value("Day", shortDayLabel(day.date)),
                                    y: .value("Minutes", day.minutesUsed)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color("AppAccent").opacity(0.35),
                                            Color("AppAccent").opacity(0.02)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                            .frame(height: 160)
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Breakdown")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))

                            Chart(categoryBreakdown, id: \.name) { item in
                                BarMark(
                                    x: .value("Count", item.value),
                                    y: .value("Category", item.name)
                                )
                                .foregroundStyle(item.color)
                                .cornerRadius(6)
                            }
                            .frame(height: 180)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(categoryBreakdown, id: \.name) { item in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(item.color)
                                            .frame(width: 8, height: 8)
                                        Text(item.name)
                                            .font(.caption)
                                            .foregroundStyle(Color("AppTextSecondary"))
                                            .lineLimit(1)
                                        Spacer(minLength: 0)
                                        Text("\(item.value)")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(Color("AppTextPrimary"))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(16)
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .dismissKeyboardOnTap()
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCell("Streak", "\(store.stats.streakDays)d", "flame.fill")
            summaryCell("Sessions", "\(store.stats.totalSessionsCompleted)", "bolt.fill")
            summaryCell("Minutes", "\(store.stats.totalMinutesUsed)", "clock.fill")
            summaryCell("Badges", "\(store.achievementsUnlocked.count)", "trophy.fill")
        }
    }

    private func summaryCell(_ title: String, _ value: String, _ icon: String) -> some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Color("AppPrimary"))
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func shortDayLabel(_ dateKey: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateKey) else { return dateKey }
        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.dateFormat = "EEE"
        return out.string(from: date)
    }
}
