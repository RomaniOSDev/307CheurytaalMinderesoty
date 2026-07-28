import SwiftUI

struct KitchenView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var segment = 0
    @State private var showConverter = false

    private var tip: String { DailyContent.tipForToday() }
    private var challenge: DailyChallenge { DailyContent.challengeForToday() }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dailyCard
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                Picker("Kitchen", selection: $segment) {
                    Text("Cart").tag(0)
                    Text("Timers").tag(1)
                    Text("Plan").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .onChange(of: segment) { _ in
                    HapticService.light()
                }

                Group {
                    if segment == 0 {
                        CartSegmentView()
                    } else if segment == 1 {
                        TimersSegmentView()
                    } else {
                        MealPlanSegmentView()
                    }
                }
            }
            .navigationTitle("Kitchen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showConverter = true
                    } label: {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(Color("AppAccent"))
                    }
                }
            }
            .screenBackground()
            .dismissKeyboardOnTap()
            .sheet(isPresented: $showConverter) {
                UnitConverterView()
            }
        }
    }

    private var dailyCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color("AppAccent"))
                    Text("Daily Tip")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                    Spacer()
                }
                Text(tip)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .fixedSize(horizontal: false, vertical: true)

                Divider().overlay(Color("AppAccent").opacity(0.25))

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: store.isChallengeCompleteToday ? "checkmark.seal.fill" : "flag.fill")
                        .foregroundStyle(store.isChallengeCompleteToday ? Color("AppPrimary") : Color("AppAccent"))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(store.isChallengeCompleteToday ? "Completed today — nice work!" : challenge.detail)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}
