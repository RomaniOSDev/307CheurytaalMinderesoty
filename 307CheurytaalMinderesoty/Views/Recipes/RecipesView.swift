import SwiftUI

struct RecipesView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var query = ""
    @State private var filterFavorites = false
    @State private var filterFromCart = false
    @State private var filterVegetarian = false
    @State private var filterQuick = false
    @State private var selectedRecipe: Recipe?
    @State private var appear = false
    @FocusState private var searchFocused: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var anyFilterActive: Bool {
        filterFavorites || filterFromCart || filterVegetarian || filterQuick
    }

    private var filtered: [Recipe] {
        store.recipesMatching(
            query: query,
            favoritesOnly: filterFavorites,
            fromCart: filterFromCart,
            vegetarianOnly: filterVegetarian,
            quickOnly: filterQuick
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                bannerHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                searchBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                filterChips
                    .padding(.bottom, 8)

                if filterFavorites && !anyOtherThanFavorites && filtered.isEmpty {
                    EmptyStateView(
                        symbol: "fork.knife",
                        title: "No Favorites Yet",
                        message: "Swipe a recipe or tap the heart to save meals you love.",
                        artImage: "img_accent"
                    )
                    .padding(.bottom, 24)
                } else if filtered.isEmpty {
                    EmptyStateView(
                        symbol: "magnifyingglass",
                        title: "No Matches",
                        message: filterFromCart && store.groceryItems.isEmpty
                            ? "Add items to your cart to find matching recipes."
                            : "Try another ingredient, filter, or recipe name.",
                        artImage: "img_card"
                    )
                    .padding(.bottom, 24)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filtered) { recipe in
                                recipeCard(recipe)
                                    .frame(maxWidth: .infinity, alignment: .top)
                                    .onTapGesture {
                                        searchFocused = false
                                        KeyboardDismiss.hide()
                                        HapticService.light()
                                        selectedRecipe = recipe
                                    }
                            }
                        }
                        .padding(16)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 12)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .navigationTitle("Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .dismissKeyboardOnTap()
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailSheet(recipe: recipe)
                    .environmentObject(store)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.45)) { appear = true }
            }
        }
    }

    private var anyOtherThanFavorites: Bool {
        filterFromCart || filterVegetarian || filterQuick || !query.isEmpty
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(title: "All", selected: !anyFilterActive) {
                    HapticService.light()
                    filterFavorites = false
                    filterFromCart = false
                    filterVegetarian = false
                    filterQuick = false
                }
                FilterChip(title: "Favorites", selected: filterFavorites) {
                    HapticService.light()
                    filterFavorites.toggle()
                }
                FilterChip(title: "From Cart", selected: filterFromCart) {
                    HapticService.light()
                    filterFromCart.toggle()
                }
                FilterChip(title: "Vegetarian", selected: filterVegetarian) {
                    HapticService.light()
                    filterVegetarian.toggle()
                }
                FilterChip(title: "Quick", selected: filterQuick) {
                    HapticService.light()
                    filterQuick.toggle()
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var bannerHeader: some View {
        SoftCard {
            HStack(spacing: 14) {
                Image("img_banner")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color("AppAccent").opacity(0.35), lineWidth: 1)
                    )
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ingredient Insights")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Search what you have and cook something new.")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    if !store.recentIngredients.isEmpty {
                        Text(store.recentIngredients.prefix(3).joined(separator: " · "))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color("AppAccent"))
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("AppPrimary"))
            TextField("Search ingredients or recipes", text: $query)
                .foregroundStyle(Color("AppTextPrimary"))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { searchFocused = false }
            if !query.isEmpty {
                Button {
                    query = ""
                    HapticService.light()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
        .padding(12)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color("AppPrimary").opacity(0.2), radius: 8, y: 4)
    }

    private func recipeCard(_ recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Color("AppBackground").opacity(0.35)
                    .frame(maxWidth: .infinity)
                    .frame(height: 96)
                    .overlay {
                        Image(recipe.imageName)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    store.toggleFavorite(recipe.id)
                } label: {
                    Image(systemName: store.isFavorite(recipe.id) ? "heart.fill" : "heart")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(8)
                        .background(Color("AppBackground").opacity(0.7))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(8)
            }

            Text(recipe.name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .topLeading)
                .minimumScaleFactor(0.8)

            HStack(spacing: 8) {
                Label(recipe.cookTimeLabel, systemImage: "clock.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color("AppAccent"))
                Spacer(minLength: 0)
                Image(systemName: recipe.isVegetarian ? "leaf.fill" : "fork.knife.circle.fill")
                    .foregroundStyle(recipe.isVegetarian ? Color("AppPrimary") : Color("AppTextSecondary"))
                    .font(.caption)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color("AppSurface"), Color("AppSurface").opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color("AppPrimary").opacity(0.25), radius: 12, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color("AppAccent").opacity(0.28), lineWidth: 1)
        )
        .contextMenu {
            Button {
                store.toggleFavorite(recipe.id)
            } label: {
                Label(
                    store.isFavorite(recipe.id) ? "Remove Favorite" : "Add Favorite",
                    systemImage: store.isFavorite(recipe.id) ? "heart.slash" : "heart"
                )
            }
        }
    }
}
