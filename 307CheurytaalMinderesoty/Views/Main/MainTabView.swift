import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var selected = 0

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selected) {
                RecipesView()
                    .tabItem { Label("Recipes", systemImage: "fork.knife") }
                    .tag(0)
                KitchenView()
                    .tabItem { Label("Kitchen", systemImage: "refrigerator.fill") }
                    .tag(1)
                StatisticsView()
                    .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                    .tag(2)
                AchievementsView()
                    .tabItem { Label("Achievements", systemImage: "trophy.fill") }
                    .tag(3)
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    .tag(4)
            }
            .tint(Color("AppPrimary"))

            if let title = store.bannerTitle {
                AchievementBanner(title: title)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                    .zIndex(10)
            }

            if store.showSuccessFlash {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Color("AppAccent"))
                    .shadow(color: Color("AppAccent").opacity(0.55), radius: 16)
                    .transition(.scale.combined(with: .opacity))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(false)
                    .zIndex(9)
            }
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(named: "AppSurface")
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            store.noteSessionBecameActive()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                store.noteSessionBecameActive()
            case .inactive, .background:
                store.noteSessionBecameInactive()
            @unknown default:
                break
            }
        }
    }
}
