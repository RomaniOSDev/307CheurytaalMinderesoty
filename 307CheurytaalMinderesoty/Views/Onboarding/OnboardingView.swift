import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var page = 0
    @State private var appearScale: CGFloat = 0.7
    @State private var appearOpacity: Double = 0

    private let pages: [(title: String, body: String, symbol: String, image: String)] = [
        ("Get Inspired", "Discover creative meal ideas using what you have.", "lightbulb.fill", "img_banner"),
        ("Swap Ingredients", "Easily find alternatives for missing items in your pantry.", "arrow.left.arrow.right", "img_card"),
        ("Start Cooking", "Dive into preparing your next meal with guidance.", "flame.fill", "img_accent")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(pages[index], index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: page)

            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Color("AppPrimary") : Color("AppTextSecondary").opacity(0.35))
                        .frame(width: index == page ? 28 : 8, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                }
            }
            .padding(.bottom, 18)

            Button {
                HapticService.light()
                if page < pages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                } else {
                    store.completeOnboarding()
                }
            } label: {
                Text(page < pages.count - 1 ? "Next" : "Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .screenBackground()
        .onChange(of: page) { _ in
            appearScale = 0.7
            appearOpacity = 0
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appearScale = 1
                appearOpacity = 1
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appearScale = 1
                appearOpacity = 1
            }
        }
    }

    private func onboardingPage(_ item: (title: String, body: String, symbol: String, image: String), index: Int) -> some View {
        VStack(spacing: 26) {
            Spacer(minLength: 20)

            ZStack {
                Image(item.image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(index == page ? appearScale : 0.92)
                    .opacity(index == page ? appearOpacity : 0.65)

                LinearGradient(
                    colors: [
                        Color("AppBackground").opacity(0.2),
                        Color("AppBackground").opacity(0.65)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Image(systemName: item.symbol)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(Color("AppPrimary"))
                    .padding(22)
                    .background(
                        Circle()
                            .fill(Color("AppBackground").opacity(0.72))
                            .shadow(color: Color("AppPrimary").opacity(0.5), radius: 16)
                    )
                    .scaleEffect(index == page ? appearScale : 0.85)
                    .opacity(index == page ? appearOpacity : 0.5)
            }
            .frame(height: 270)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color("AppAccent").opacity(0.4), lineWidth: 1)
            )
            .shadow(color: Color("AppPrimary").opacity(0.3), radius: 18, y: 10)
            .padding(.horizontal, 28)

            VStack(spacing: 12) {
                Text(item.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(item.body)
                    .font(.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 28)
            }

            Spacer()
        }
    }
}
