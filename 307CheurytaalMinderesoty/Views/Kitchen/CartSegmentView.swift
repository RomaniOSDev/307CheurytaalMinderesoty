import SwiftUI

struct CartSegmentView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showAdd = false
    @State private var shakeAdd = 0

    var body: some View {
        VStack(spacing: 0) {
            if store.groceryItems.isEmpty {
                EmptyStateView(
                    symbol: "cart.fill",
                    title: "Cart is Empty",
                    message: "Add groceries by category and check them off as you shop.",
                    actionTitle: "Add Item",
                    action: { showAdd = true },
                    artImage: "img_card"
                )
            } else {
                List {
                    ForEach(GroceryCategory.allCases) { category in
                        let items = store.groceryItems.filter { $0.category == category }
                        if !items.isEmpty {
                            Section {
                                ForEach(items) { item in
                                    groceryRow(item)
                                        .listRowBackground(Color("AppSurface").opacity(0.55))
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                store.deleteGroceryItem(item)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button {
                                                store.togglePurchased(item)
                                            } label: {
                                                Label(
                                                    item.isPurchased ? "Undo" : "Bought",
                                                    systemImage: item.isPurchased ? "arrow.uturn.left" : "checkmark"
                                                )
                                            }
                                            .tint(Color("AppPrimary"))
                                        }
                                }
                            } header: {
                                Label(category.rawValue, systemImage: category.icon)
                                    .foregroundStyle(Color("AppAccent"))
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }

            HStack(spacing: 12) {
                Button {
                    HapticService.light()
                    showAdd = true
                } label: {
                    Label("Add Item", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                if !store.groceryItems.isEmpty {
                    ShareLink(item: store.shareListText()) {
                        Label("Share List", systemImage: "square.and.arrow.up")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(minHeight: 44)
                            .background(Color("AppSurface"))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color("AppPrimary").opacity(0.25), radius: 10, y: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color("AppAccent").opacity(0.35), lineWidth: 1)
                            )
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticService.medium()
                        HapticService.play(1104)
                    })
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $showAdd) {
            AddGrocerySheet(shakeTrigger: $shakeAdd)
                .environmentObject(store)
        }
    }

    private func groceryRow(_ item: GroceryItem) -> some View {
        Button {
            store.togglePurchased(item)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isPurchased ? Color("AppPrimary") : Color("AppTextSecondary"))
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(item.isPurchased ? Color("AppTextSecondary") : Color("AppTextPrimary"))
                        .strikethrough(item.isPurchased)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(item.quantity)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                Spacer()
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}

struct AddGrocerySheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @Binding var shakeTrigger: Int

    @State private var name = ""
    @State private var quantity = "1"
    @State private var category: GroceryCategory = .vegetables
    @State private var localShake = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                        .modifier(ShakeEffect(animatableData: CGFloat(localShake)))
                    TextField("Quantity", text: $quantity)
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(GroceryCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(Color("AppBackground"))
            .navigationTitle("Add Grocery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        KeyboardDismiss.hide()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        KeyboardDismiss.hide()
                        if store.addGroceryItem(name: name, quantity: quantity, category: category) != nil {
                            dismiss()
                        } else {
                            HapticService.warning()
                            withAnimation(.default) { localShake += 1 }
                        }
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .dismissKeyboardOnTap()
    }
}
