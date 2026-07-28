import SwiftUI

struct RecipeDetailSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe

    @State private var servings: Int = 2
    @State private var showCookMode = false
    @State private var showConverter = false
    @State private var noteText = ""
    @State private var cartMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Image(recipe.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color("AppAccent").opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color("AppPrimary").opacity(0.3), radius: 14, y: 8)

                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(recipe.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            HStack(spacing: 14) {
                                Label(recipe.cookTimeLabel, systemImage: "clock.fill")
                                Label(
                                    recipe.isVegetarian ? "Vegetarian" : "Non-veg",
                                    systemImage: recipe.isVegetarian ? "leaf.fill" : "fork.knife"
                                )
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppAccent"))
                        }
                    }

                    SoftCard {
                        VStack(spacing: 12) {
                            Button {
                                showCookMode = true
                            } label: {
                                Label("Start Cooking", systemImage: "flame.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())

                            Button {
                                let added = store.addRecipeIngredientsToCart(recipe)
                                cartMessage = added > 0
                                    ? "Added \(added) item\(added == 1 ? "" : "s") to cart"
                                    : "All ingredients already in cart"
                                HapticService.light()
                            } label: {
                                Label("Add Ingredients to Cart", systemImage: "cart.badge.plus")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color("AppSurface"))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color("AppAccent").opacity(0.35), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)

                            if let cartMessage {
                                Text(cartMessage)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppPrimary"))
                            }

                            Button {
                                showConverter = true
                            } label: {
                                Label("Unit Converter", systemImage: "scalemass.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color("AppAccent"))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Servings")
                                    .font(.headline)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Spacer()
                                Stepper(value: $servings, in: 1...12) {
                                    Text("\(servings)")
                                        .font(.headline.monospacedDigit())
                                        .foregroundStyle(Color("AppAccent"))
                                }
                            }
                            Text("Base recipe is \(recipe.baseServings) servings.")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ingredients for \(servings) servings")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            ForEach(recipe.ingredients, id: \.self) { item in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Color("AppPrimary"))
                                        .frame(width: 7, height: 7)
                                        .shadow(color: Color("AppPrimary").opacity(0.5), radius: 4)
                                    Text(recipe.scaledIngredientDisplay(item, servings: servings))
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                }
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Steps")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .frame(width: 26, height: 26)
                                        .background(
                                            LinearGradient(
                                                colors: [Color("AppPrimary"), Color("AppAccent")],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .clipShape(Circle())
                                    Text(step)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ingredient Swaps")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            ForEach(recipe.swaps) { swap in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(swap.original)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color("AppTextPrimary"))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                        Image(systemName: "arrow.right")
                                            .font(.caption2)
                                            .foregroundStyle(Color("AppPrimary"))
                                        Text(swap.alternative)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color("AppAccent"))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    Text(swap.note)
                                        .font(.caption)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    notesCard
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        HapticService.light()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.toggleFavorite(recipe.id)
                    } label: {
                        Image(systemName: store.isFavorite(recipe.id) ? "heart.fill" : "heart")
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
            }
            .screenBackground()
            .dismissKeyboardOnTap()
            .onAppear {
                servings = recipe.baseServings
                noteText = store.note(for: recipe.id).note
                store.markRecipeViewed(recipe.id)
            }
            .fullScreenCover(isPresented: $showCookMode) {
                CookModeView(recipe: recipe)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showConverter) {
                UnitConverterView()
            }
        }
    }

    private var notesCard: some View {
        let current = store.note(for: recipe.id)
        return SoftCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Notes & Rating")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            store.updateRating(recipeId: recipe.id, rating: star)
                        } label: {
                            Image(systemName: star <= current.rating ? "star.fill" : "star")
                                .foregroundStyle(Color("AppAccent"))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    Button {
                        let next: Bool? = current.liked == true ? nil : true
                        store.updateLiked(recipeId: recipe.id, liked: next)
                    } label: {
                        Image(systemName: current.liked == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .foregroundStyle(current.liked == true ? Color("AppPrimary") : Color("AppTextSecondary"))
                    }
                    .buttonStyle(.plain)
                    Button {
                        let next: Bool? = current.liked == false ? nil : false
                        store.updateLiked(recipeId: recipe.id, liked: next)
                    } label: {
                        Image(systemName: current.liked == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .foregroundStyle(current.liked == false ? Color.red.opacity(0.85) : Color("AppTextSecondary"))
                    }
                    .buttonStyle(.plain)
                }

                TextField("Personal notes…", text: $noteText, axis: .vertical)
                    .lineLimit(3...6)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .padding(10)
                    .background(Color("AppBackground").opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onChange(of: noteText) { newValue in
                        store.updateNote(recipeId: recipe.id, text: newValue)
                    }
            }
        }
    }
}
